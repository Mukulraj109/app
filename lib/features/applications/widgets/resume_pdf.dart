import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../../../api/api_client.dart';
import '../../../theme/home_tokens.dart';

/// Lightweight in-memory PDF bytes. During **Review** only one resume is kept;
/// bytes are dropped when Review closes or the card advances.
class ResumePdfCache {
  ResumePdfCache._();

  static final ResumePdfCache instance = ResumePdfCache._();

  static const int _viewerMaxEntries = 4;
  static const int _diskMaxEntries = 8;

  final Map<String, Uint8List> _bytes = {};
  final Map<String, Future<Uint8List?>> _inFlight = {};

  bool _inReviewSession = false;
  int _sessionEpoch = 0;

  bool get inReviewSession => _inReviewSession;

  /// Called when Review mode opens — clears prior PDF data and limits to one resume.
  void beginReviewSession() {
    _inReviewSession = true;
    _sessionEpoch++;
    clear();
  }

  /// Called when Review closes — drops all cached PDF bytes and cancels logical in-flight work.
  void endReviewSession() {
    if (!_inReviewSession) return;
    _inReviewSession = false;
    _sessionEpoch++;
    _inFlight.clear();
    clear();
  }

  void clear() => _bytes.clear();

  void evict(String resumeId) {
    if (resumeId.isEmpty) return;
    _bytes.remove(resumeId);
  }

  Uint8List? peek(String resumeId) {
    if (resumeId.isEmpty) return null;
    return _bytes[resumeId];
  }

  void put(String resumeId, Uint8List data) {
    if (resumeId.isEmpty) return;
    _remember(resumeId, data);
    _writeDisk(resumeId, data);
  }

  Future<Uint8List?> load(ApiClient? api, String resumeId) async {
    if (resumeId.isEmpty) return null;
    final cached = _bytes[resumeId];
    if (cached != null) return cached;

    final onDisk = await _readDisk(resumeId);
    if (onDisk != null) {
      _remember(resumeId, onDisk);
      return onDisk;
    }
    if (api == null) return null;

    final inFlight = _inFlight[resumeId];
    if (inFlight != null) return inFlight;

    final epoch = _sessionEpoch;
    final future = _fetch(api, resumeId, epoch);
    _inFlight[resumeId] = future;
    try {
      return await future;
    } finally {
      _inFlight.remove(resumeId);
    }
  }

  void _remember(String resumeId, Uint8List data) {
    if (_inReviewSession) {
      _bytes
        ..clear()
        ..[resumeId] = data;
    } else {
      _bytes[resumeId] = data;
      _trimOutsideReview();
    }
  }

  Directory _diskDir() {
    final dir = Directory(
      '${Directory.systemTemp.path}${Platform.pathSeparator}firststep_resume_pdf',
    );
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  String _diskName(String resumeId) {
    final cleaned = resumeId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final name = cleaned.length > 96 ? cleaned.substring(0, 96) : cleaned;
    return '$name.pdf';
  }

  Future<Uint8List?> _readDisk(String resumeId) async {
    try {
      final file = File(
        '${_diskDir().path}${Platform.pathSeparator}${_diskName(resumeId)}',
      );
      if (!file.existsSync()) return null;
      final bytes = await file.readAsBytes();
      await file.setLastModified(DateTime.now());
      return bytes;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeDisk(String resumeId, Uint8List data) async {
    try {
      final dir = _diskDir();
      final file = File('${dir.path}${Platform.pathSeparator}${_diskName(resumeId)}');
      await file.writeAsBytes(data, flush: true);
      final files = dir
          .listSync()
          .whereType<File>()
          .toList()
        ..sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
      while (files.length > _diskMaxEntries) {
        try {
          files.removeAt(0).deleteSync();
        } catch (_) {
          break;
        }
      }
    } catch (_) {
      /* memory cache still serves this session */
    }
  }

  Future<Uint8List?> _fetch(ApiClient api, String resumeId, int epoch) async {
    try {
      final raw = await api.downloadResumeFile(resumeId);
      final data = Uint8List.fromList(raw);
      await _writeDisk(resumeId, data);
      if (_inReviewSession && epoch != _sessionEpoch) return null;
      _remember(resumeId, data);
      return data;
    } catch (e) {
      rethrow;
    }
  }

  void _trimOutsideReview() {
    if (_inReviewSession || _bytes.length <= _viewerMaxEntries) return;
    final keys = _bytes.keys.toList();
    final remove = keys.length - _viewerMaxEntries;
    for (var i = 0; i < remove; i++) {
      _bytes.remove(keys[i]);
    }
  }
}

/// Placeholder stripes when PDF is not loaded (stacked cards behind the front card).
class ResumePdfPlaceholder extends StatelessWidget {
  const ResumePdfPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 9,
            width: 80,
            color: const Color(0xFF14232B),
          ),
          const SizedBox(height: 10),
          for (final w in [0.9, 0.7, 0.85, 0.5, 0.75, 0.6, 0.8, 0.55]) ...[
            FractionallySizedBox(
              widthFactor: w,
              child: Container(
                height: 5,
                margin: const EdgeInsets.only(bottom: 7),
                color: const Color(0xFFE3E6E8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// First-page resume preview inside the Review swipe card (front card only).
class ResumeInlinePreview extends StatefulWidget {
  final String resumeId;
  final ApiClient? api;

  const ResumeInlinePreview({
    super.key,
    required this.resumeId,
    this.api,
  });

  @override
  State<ResumeInlinePreview> createState() => _ResumeInlinePreviewState();
}

class _ResumeInlinePreviewState extends State<ResumeInlinePreview> {
  PdfController? _controller;
  Object? _error;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _open();
  }

  @override
  void didUpdateWidget(covariant ResumeInlinePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resumeId != widget.resumeId) {
      final cache = ResumePdfCache.instance;
      if (cache.inReviewSession) {
        cache.evict(oldWidget.resumeId);
      }
      _disposeController();
      _error = null;
      _open();
    }
  }

  Future<void> _open() async {
    final loadId = ++_loadGeneration;
    if (widget.resumeId.isEmpty) {
      setState(() => _error = 'missing_id');
      return;
    }
    try {
      final bytes = await ResumePdfCache.instance.load(widget.api, widget.resumeId);
      if (!mounted || loadId != _loadGeneration) return;
      if (bytes == null) {
        setState(() => _error = 'unavailable');
        return;
      }
      final controller = PdfController(
        document: PdfDocument.openData(bytes),
        initialPage: 1,
      );
      if (!mounted || loadId != _loadGeneration) {
        controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _error = null;
      });
    } catch (e) {
      if (!mounted || loadId != _loadGeneration) return;
      setState(() => _error = e);
    }
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
  }

  @override
  void dispose() {
    _loadGeneration++;
    _disposeController();
    final cache = ResumePdfCache.instance;
    if (cache.inReviewSession) {
      cache.evict(widget.resumeId);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    if (_error != null) {
      return Center(
        child: Text(
          'Could not load resume',
          style: TextStyle(fontSize: 13, color: t.mute),
        ),
      );
    }
    final controller = _controller;
    if (controller == null) {
      return Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: t.teal),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ColoredBox(
        color: Colors.white,
        child: PdfView(
          controller: controller,
          scrollDirection: Axis.vertical,
          physics: const NeverScrollableScrollPhysics(),
          backgroundDecoration: const BoxDecoration(color: Colors.white),
        ),
      ),
    );
  }
}

/// Full-screen pinch-zoom PDF viewer (replaces mock paper pages).
class ResumeFullScreenPdf extends StatefulWidget {
  final String resumeId;
  final ApiClient? api;
  final ValueChanged<int>? onPageChanged;
  final void Function(int? pageCount)? onDocumentReady;

  const ResumeFullScreenPdf({
    super.key,
    required this.resumeId,
    this.api,
    this.onPageChanged,
    this.onDocumentReady,
  });

  @override
  State<ResumeFullScreenPdf> createState() => _ResumeFullScreenPdfState();
}

class _ResumeFullScreenPdfState extends State<ResumeFullScreenPdf> {
  PdfControllerPinch? _controller;
  Object? _error;
  int _loadGeneration = 0;

  void _onLoadingState() {
    final c = _controller;
    if (c == null) return;
    if (c.loadingState.value == PdfLoadingState.success) {
      widget.onDocumentReady?.call(c.pagesCount);
    }
  }

  void _onPage() {
    final c = _controller;
    if (c == null) return;
    widget.onPageChanged?.call(c.pageListenable.value);
  }

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    final loadId = ++_loadGeneration;
    if (widget.resumeId.isEmpty) {
      setState(() => _error = 'missing_id');
      return;
    }
    try {
      final bytes = await ResumePdfCache.instance.load(widget.api, widget.resumeId);
      if (!mounted || loadId != _loadGeneration) return;
      if (bytes == null) {
        setState(() => _error = 'unavailable');
        return;
      }
      final controller = PdfControllerPinch(
        document: PdfDocument.openData(bytes),
      );
      controller.loadingState.addListener(_onLoadingState);
      controller.pageListenable.addListener(_onPage);
      if (!mounted || loadId != _loadGeneration) {
        controller.loadingState.removeListener(_onLoadingState);
        controller.pageListenable.removeListener(_onPage);
        controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _error = null;
      });
    } catch (e) {
      if (!mounted || loadId != _loadGeneration) return;
      setState(() => _error = e);
    }
  }

  @override
  void dispose() {
    _loadGeneration++;
    _controller?.loadingState.removeListener(_onLoadingState);
    _controller?.pageListenable.removeListener(_onPage);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.picture_as_pdf_outlined, size: 48, color: t.mute),
              const SizedBox(height: 12),
              Text(
                'Could not load this resume.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _controller?.dispose();
                    _controller = null;
                  });
                  _open();
                },
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }
    final controller = _controller;
    if (controller == null) {
      return Center(
        child: CircularProgressIndicator(color: t.teal),
      );
    }
    return PdfViewPinch(
      controller: controller,
      backgroundDecoration: const BoxDecoration(color: Color(0xFF1B1F22)),
    );
  }
}