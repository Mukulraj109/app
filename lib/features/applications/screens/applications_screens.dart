import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../api/api_client.dart';
import '../../../shared_widgets/app_nav.dart';
import '../../../theme/home_tokens.dart';
import '../applications_store.dart';
import '../widgets/resume_pdf.dart';

void showAppsToast(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(milliseconds: 2600),
    ),
  );
}

Pastel pastelOf(HomeTokens t, String key) {
  switch (key) {
    case 'mint':
      return t.mint;
    case 'sky':
      return t.sky;
    case 'pch':
      return t.peach;
    case 'but':
      return t.butter;
    case 'lav':
    default:
      return t.lavender;
  }
}

Future<void> openRequestsSheet(BuildContext context, ApplicationsStore store) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: HomeTokens.of(context).card,
    isScrollControlled: true,
    useSafeArea: !kIsWeb && Platform.isIOS,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (sheet) {
      final h = MediaQuery.sizeOf(sheet).height * 0.8;
      return SizedBox(height: h, child: _RequestsBody(store: store));
    },
  );
}

class _RequestsBody extends StatefulWidget {
  const _RequestsBody({required this.store});
  final ApplicationsStore store;

  @override
  State<_RequestsBody> createState() => _RequestsBodyState();
}

class _RequestsBodyState extends State<_RequestsBody> {
  final _url = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final api = widget.store.api;
    final url = _url.text.trim();
    if (api == null || url.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await api.createJobRequest(url);
      await widget.store.loadJobRequests();
      _url.clear();
      if (mounted) setState(() => _busy = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not save that link.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final requests = widget.store.requests;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(color: t.line, borderRadius: BorderRadius.circular(3)),
              ),
            ),
            const SizedBox(height: 14),
            Text('Your requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: t.ink)),
            const SizedBox(height: 8),
            TextField(
              controller: _url,
              decoration: const InputDecoration(hintText: 'Paste a job URL'),
            ),
            if (_error != null) Text(_error!, style: TextStyle(color: t.ink)),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _busy ? null : _submit,
                child: Text(_busy ? 'Saving…' : 'Request'),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final r in requests) ...[
                    _RequestRow(request: r),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestRow extends StatelessWidget {
  final AppRequest request;
  const _RequestRow({required this.request});

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final p = pastelOf(t, 'lav');
    final applied = request.isApplied;
    final chip = applied ? t.mint : t.butter;
    final sourceLabel = request.source.trim().isEmpty
        ? 'paste'
        : request.source;
    final subtitle = [
      if (request.createdLabel.isNotEmpty) request.createdLabel,
      sourceLabel,
    ].join(' · ');
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: p.bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            request.host.isEmpty ? '?' : request.host[0].toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: p.fg,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                request.host,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: t.ink,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: t.mute),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (request.url.isNotEmpty)
                Text(
                  request.url,
                  style: TextStyle(fontSize: 11, color: t.mute),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: chip.bg,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            applied ? 'Applied ✓' : request.statusLabel,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: chip.fg,
            ),
          ),
        ),
      ],
    );
  }
}

/// [resume] kept for call-site compatibility; list matches web for all plans.
Future<String?> openReasonSheet(BuildContext context, {required bool resume}) {
  final t = HomeTokens.of(context);
  // Match web THUMB_DOWN_REASONS (firststep_frontend/src/constants/jobFeedbackReasons.ts).
  final reasons = <String>[
    'Job not relevant',
    'Exp mismatch',
    'Incorrect resume',
    'Referral company',
    'Incomplete application',
    'Incorrect tagging',
    'Others',
  ];
  // Keep [resume] referenced for stable call sites across plan variants.
  final _ = resume;
  var selected = -1;
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: t.card,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (sheet) {
      final h = MediaQuery.sizeOf(sheet).height * 0.8;
      return StatefulBuilder(
        builder: (context, setLocal) {
          return SizedBox(
            height: h,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: t.line,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),
                  Text(
                    'What went wrong?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: t.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pick one. Your AIC sees this right away.',
                    style: TextStyle(fontSize: 13, color: t.mute),
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < reasons.length; i++) ...[
                    InkWell(
                      onTap: () => setLocal(() => selected = i),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: selected == i ? t.tealSoft : t.bg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected == i ? t.teal : t.line,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected == i ? t.teal : t.mute,
                                  width: 2,
                                ),
                                color: selected == i ? t.teal : Colors.transparent,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                reasons[i],
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: t.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: t.navy,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: selected < 0
                          ? null
                          : () => Navigator.pop(sheet, reasons[selected]),
                      child: const Text(
                        'Send',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'You can change your rating anytime.',
                      style: TextStyle(fontSize: 12, color: t.mute),
                    ),
                  ),
                ],
              ),
            ),
          ),
          );
        },
      );
    },
  );
}

Future<void> openResumeViewer(BuildContext context, AppJob job, {ApplicationsStore? store}) {
  final t = HomeTokens.of(context);
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 450),
    pageBuilder: (ctx, a1, a2) {
      return _ResumeViewer(job: job, tokens: t, store: store);
    },
    transitionBuilder: (ctx, anim, _, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      );
    },
  );
}

/// Download T&Cs — all toggles required; nothing persisted.
Future<bool> openResumeDownloadAck(BuildContext context) async {
  final t = HomeTokens.of(context);
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: t.card,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (sheet) => const _ResumeDownloadAckSheet(),
  );
  return result == true;
}

Future<void> downloadResumeWithAck(
  BuildContext context,
  AppJob job, {
  ApplicationsStore? store,
}) async {
  final ok = await openResumeDownloadAck(context);
  if (!ok || !context.mounted) return;
  final api = store?.api;
  if (api == null || job.resumeId.isEmpty) {
    await shareText(
      context,
      'Resume · ${job.company}',
      'https://firststepjob.com/resumes/${job.id}',
    );
    return;
  }
  try {
    final bytes = await api.downloadResumeFile(job.resumeId);
    ResumePdfCache.instance.put(job.resumeId, Uint8List.fromList(bytes));
    final file = File('${Directory.systemTemp.path}/firststep-${job.resumeId}.pdf');
    await file.writeAsBytes(bytes, flush: true);
    store?.markResumeDownloaded(job.resumeId);
    if (!context.mounted) return;
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Resume · ${job.company}',
    );
  } on ApiException catch (err) {
    if (!context.mounted) return;
    showAppsToast(context, err.message);
  } catch (_) {
    if (!context.mounted) return;
    showAppsToast(context, 'Could not download the resume.');
  }
}

// Callers: openResumeViewer → applications_view / _OtherResumes.
class _ResumeViewer extends StatefulWidget {
  final AppJob job;
  final HomeTokens tokens;
  final ApplicationsStore? store;

  const _ResumeViewer({required this.job, required this.tokens, this.store});

  @override
  State<_ResumeViewer> createState() => _ResumeViewerState();
}

class _ResumeViewerState extends State<_ResumeViewer> {
  int _page = 1;
  int _pageCount = 0;

  AppJob get job => widget.job;
  ApplicationsStore? get store => widget.store;

  Widget _frostBtn({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white.withValues(alpha: 0.1),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1B1F22),
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  child: Row(
                    children: [
                      _frostBtn(
                        icon: Icons.close,
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Resume · ${job.company}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              _pageCount > 0
                                  ? '${job.role} · $_pageCount ${_pageCount == 1 ? 'page' : 'pages'}'
                                  : job.role,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _frostBtn(
                        icon: Icons.ios_share,
                        onTap: () => shareText(
                          context,
                          'Resume · ${job.company}',
                          'https://firststepjob.com/resumes/${job.id}',
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ResumeFullScreenPdf(
                    resumeId: job.resumeId,
                    api: store?.api,
                    onPageChanged: (p) {
                      if (_page != p) setState(() => _page = p);
                    },
                    onDocumentReady: (count) {
                      final n = count ?? 0;
                      if (_pageCount != n) setState(() => _pageCount = n);
                    },
                  ),
                ),
                Container(
                  color: const Color(0xFF141719),
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Material(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                onTap: () =>
                                    downloadResumeWithAck(context, job, store: store),
                                borderRadius: BorderRadius.circular(14),
                                child: const SizedBox(
                                  height: 48,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.download_outlined,
                                          size: 18, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text(
                                        'Download',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                onTap: () => shareText(
                                  context,
                                  'Resume · ${job.company}',
                                  'https://firststepjob.com/resumes/${job.id}',
                                ),
                                borderRadius: BorderRadius.circular(14),
                                child: const SizedBox(
                                  height: 48,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.ios_share,
                                          size: 18, color: Color(0xFF14232B)),
                                      SizedBox(width: 8),
                                      Text(
                                        'Share',
                                        style: TextStyle(
                                          color: Color(0xFF14232B),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Resume created · Powered by FirstStep',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 130,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _pageCount > 0 ? '$_page / $_pageCount' : '…',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumeDownloadAckSheet extends StatefulWidget {
  const _ResumeDownloadAckSheet();

  @override
  State<_ResumeDownloadAckSheet> createState() =>
      _ResumeDownloadAckSheetState();
}

class _ResumeDownloadAckSheetState extends State<_ResumeDownloadAckSheet> {
  bool personal = false;
  bool noShare = false;
  bool liability = false;

  bool get _all => personal && noShare && liability;

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: t.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Before you download',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: t.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Acknowledge these terms to continue. We do not store your answers.',
            style: TextStyle(fontSize: 13.5, color: t.mute, height: 1.4),
          ),
          const SizedBox(height: 14),
          _ackTile(
            t: t,
            value: personal,
            onChanged: (v) => setState(() => personal = v),
            label: 'I will only use this resume for my own job applications.',
          ),
          _ackTile(
            t: t,
            value: noShare,
            onChanged: (v) => setState(() => noShare = v),
            label:
                'I will not share or redistribute this resume with anyone else.',
          ),
          _ackTile(
            t: t,
            value: liability,
            onChanged: (v) => setState(() => liability = v),
            label:
                'I understand misuse of this resume is my responsibility, not FirstStep’s.',
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _all
                  ? () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context, true);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: t.ctaBg,
                foregroundColor: t.ctaInk,
                disabledBackgroundColor: t.line,
                disabledForegroundColor: t.mute,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Agree and download',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ackTile({
    required HomeTokens t,
    required bool value,
    required ValueChanged<bool> onChanged,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: t.line),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: value,
                  onChanged: (v) => onChanged(v ?? false),
                  activeColor: t.teal,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.35,
                    color: t.ink,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> openResponseImage(BuildContext context, AppResponse response) {
  final proof = response.proofUrl.trim();
  if (proof.startsWith('http://') || proof.startsWith('https://')) {
    return openExternal(proof);
  }
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.black87,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (ctx, _, __) {
      return GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    response.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    [
                      response.tag,
                      if (response.subtitle.isNotEmpty) response.subtitle,
                      if (response.received.isNotEmpty) 'Received ${response.received}',
                      if (response.due != null && response.due!.isNotEmpty) 'Due ${response.due}',
                    ].join(' · '),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F2F4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'No attachment on this response.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tap anywhere to close',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Full-screen Review mode overlay.
class ReviewModeOverlay extends StatefulWidget {
  final ApplicationsStore store;
  final VoidCallback onClose;

  const ReviewModeOverlay({
    super.key,
    required this.store,
    required this.onClose,
  });

  @override
  State<ReviewModeOverlay> createState() => _ReviewModeOverlayState();
}

class _ReviewModeOverlayState extends State<ReviewModeOverlay> {
  double _dx = 0;
  bool _advancing = false;

  ApplicationsStore get store => widget.store;

  @override
  void initState() {
    super.initState();
    ResumePdfCache.instance.beginReviewSession();
  }

  void _closeReview() {
    ResumePdfCache.instance.endReviewSession();
    widget.onClose();
  }

  @override
  void dispose() {
    ResumePdfCache.instance.endReviewSession();
    super.dispose();
  }

  Future<void> _advance(String how) async {
    if (_advancing) return;
    _advancing = true;
    HapticFeedback.mediumImpact();
    try {
      final queue = store.reviewQueue;
      if (queue.isEmpty) {
        _closeReview();
        return;
      }
      final job = queue.first;
      if (how == 'yes') {
        final ok = await store.rateUp(job);
        if (!mounted) return;
        if (!ok) {
          showAppsToast(context, 'Could not save your rating.');
          return;
        }
        store.bumpReviewIndex();
      } else if (how == 'no') {
        final reason = await openReasonSheet(
          context,
          resume: store.content.showResumes,
        );
        if (reason == null) return;
        final ok = await store.rateDown(job, reason: reason);
        if (!mounted) return;
        if (!ok) {
          showAppsToast(context, 'Could not save your rating.');
          return;
        }
        showAppsToast(context, 'Thanks. Your AIC can see this now.');
        store.bumpReviewIndex();
      } else {
        store.reviewSkip(job);
      }
      if (!mounted) return;
      setState(() => _dx = 0);
      if (store.reviewDone) {
        await Future<void>.delayed(const Duration(milliseconds: 900));
        if (mounted) _closeReview();
      }
    } finally {
      _advancing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        if (store.reviewDone) {
          return Material(
            color: t.bg,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, size: 48, color: t.mint.fg),
                  const SizedBox(height: 12),
                  Text(
                    'All done, thanks!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: t.ink,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Callers: applications_view ReviewModeOverlay. UI-only. User:
        // "Match Applications to 04-applications.html" — rv-stack 3 cards.
        final queue = store.reviewQueue;
        if (queue.isEmpty) {
          return const SizedBox.shrink();
        }
        final job = queue.first;
        final mid = queue.length > 1 ? queue[1] : job;
        final back = queue.length > 2 ? queue[2] : mid;
        final idx = store.reviewIndex;
        final progress = (idx / ApplicationsStore.reviewTotal).clamp(0.0, 1.0);

        return Material(
          color: t.bg,
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                  child: Row(
                    children: [
                      Material(
                        color: t.card,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _closeReview,
                          child: Container(
                            width: 42,
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: t.line),
                            ),
                            child: Icon(Icons.close, color: t.ink, size: 20),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Review today',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: t.ink,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 42,
                        child: Text(
                          '${idx + 1}/${ApplicationsStore.reviewTotal}',
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: 13, color: t.mute),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: t.bg,
                      color: t.teal,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: _ReviewFaceCard(
                            job: back,
                            showResume: store.content.showResumes,
                            scale: 0.9,
                            dy: 24,
                            opacity: 0.4,
                          ),
                        ),
                        Positioned.fill(
                          child: _ReviewFaceCard(
                            job: mid,
                            showResume: store.content.showResumes,
                            scale: 0.95,
                            dy: 12,
                            opacity: 0.7,
                          ),
                        ),
                        Positioned.fill(
                          child: GestureDetector(
                            onHorizontalDragUpdate: (d) {
                              setState(() => _dx += d.delta.dx);
                            },
                            onHorizontalDragEnd: (_) {
                              if (_dx.abs() > 100) {
                                _advance(_dx > 0 ? 'yes' : 'no');
                              } else {
                                setState(() => _dx = 0);
                              }
                            },
                            child: Transform.translate(
                              offset: Offset(_dx, 0),
                              child: Transform.rotate(
                                angle: _dx / 600,
                                child: _ReviewFaceCard(
                                  job: job,
                                  showResume: store.content.showResumes,
                                  scale: 1,
                                  dy: 0,
                                  opacity: 1,
                                  showStamps: true,
                                  dx: _dx,
                                  api: store.api,
                                  loadResumePdf: true,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 22, 28, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _RoundAct(
                        color: t.card,
                        iconColor: t.ink,
                        icon: Icons.thumb_down_alt_rounded,
                        bordered: true,
                        onTap: () => _advance('no'),
                      ),
                      const SizedBox(width: 26),
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: TextButton(
                          onPressed: () => _advance('skip'),
                          style: TextButton.styleFrom(
                            foregroundColor: t.mute,
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text(
                            'Skip',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 26),
                      _RoundAct(
                        color: t.mint.bg,
                        iconColor: t.mint.fg,
                        icon: Icons.thumb_up_alt_rounded,
                        bordered: false,
                        onTap: () => _advance('yes'),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    "Swipe right if it's a good fit, left if not",
                    style: TextStyle(fontSize: 12.5, color: t.mute),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Stamp extends StatelessWidget {
  final String label;
  final Color color;
  const _Stamp({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 14,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

// Importers: ReviewModeOverlay in this file; called from applications_view.
// No data I/O. User: "Match Applications to 04-applications.html"
class _RoundAct extends StatelessWidget {
  final Color color;
  final Color iconColor;
  final IconData icon;
  final VoidCallback onTap;
  final bool bordered;

  const _RoundAct({
    required this.color,
    required this.iconColor,
    required this.icon,
    required this.onTap,
    this.bordered = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return Material(
      color: color,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: bordered ? Border.all(color: t.line) : null,
            boxShadow: t.cardShadow,
          ),
          child: Icon(icon, color: iconColor, size: 26),
        ),
      ),
    );
  }
}

class _ReviewFaceCard extends StatelessWidget {
  final AppJob job;
  final bool showResume;
  final double scale;
  final double dy;
  final double opacity;
  final bool showStamps;
  final double dx;
  final ApiClient? api;
  final bool loadResumePdf;

  const _ReviewFaceCard({
    required this.job,
    required this.showResume,
    required this.scale,
    required this.dy,
    required this.opacity,
    this.showStamps = false,
    this.dx = 0,
    this.api,
    this.loadResumePdf = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final p = pastelOf(t, ApplicationsStore.pastelFor(job.industry));
    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(0, dy),
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.topCenter,
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: t.card,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: t.line),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 40,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: p.bg,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Text(
                            job.company.isEmpty ? '?' : job.company[0],
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: p.fg,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                job.role,
                                style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.4,
                                  height: 1.2,
                                  color: t.ink,
                                ),
                              ),
                              Text(
                                '${job.company} · ${job.location}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: t.mute,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: showResume
                          ? (loadResumePdf
                              ? ResumeInlinePreview(
                                  key: ValueKey('review-resume-${job.resumeId}'),
                                  resumeId: job.resumeId,
                                  api: api,
                                )
                              : const ResumePdfPlaceholder())
                          : Text(
                              '${job.company} is looking for a ${job.role} to build and own reliable data pipelines…',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.55,
                                color: t.mute,
                              ),
                            ),
                    ),
                  ],
                ),
                if (showStamps) ...[
                  Positioned(
                    top: 2,
                    left: 0,
                    child: Opacity(
                      opacity: (dx / 100).clamp(0.0, 1.0),
                      child: Transform.rotate(
                        angle: -0.17,
                        child: _Stamp(label: 'GOOD', color: t.mint.fg),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 0,
                    child: Opacity(
                      opacity: (-dx / 100).clamp(0.0, 1.0),
                      child: Transform.rotate(
                        angle: 0.17,
                        child: _Stamp(label: 'NOT GOOD', color: t.ink),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
