import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../api/api_client.dart';
import '../../../theme/home_tokens.dart';

Future<void> openBellInbox(BuildContext context, ApiClient? api) {
  final t = HomeTokens.of(context);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: t.card,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (sheet) {
      final h = MediaQuery.sizeOf(sheet).height * 0.85;
      return SizedBox(height: h, child: BellInboxPage(api: api));
    },
  );
}

class BellInboxPage extends StatefulWidget {
  const BellInboxPage({super.key, this.api});

  final ApiClient? api;

  @override
  State<BellInboxPage> createState() => _BellInboxPageState();
}

class _BellInboxPageState extends State<BellInboxPage> {
  List<Map<String, dynamic>> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = widget.api;
    if (api == null) {
      setState(() {
        _loading = false;
        _error = 'Sign in to see notifications.';
      });
      return;
    }
    try {
      final json = await api.getBell();
      final raw = json['notifications'];
      final items = raw is List
          ? raw.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList()
          : <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load notifications.';
      });
    }
  }

  Future<void> _open(Map<String, dynamic> item) async {
    final api = widget.api;
    final id = '${item['_id']}';
    if (api != null && id.isNotEmpty && item['markedAsRead'] != true) {
      try {
        await api.markBellRead(id);
      } catch (_) {}
    }
    final meta = item['metadata'];
    final map = meta is Map ? Map<String, dynamic>.from(meta) : const <String, dynamic>{};
    final link = '${map['link'] ?? map['route'] ?? ''}'.trim();
    if (link.startsWith('http')) {
      final uri = Uri.tryParse(link);
      if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: t.line, borderRadius: BorderRadius.circular(2)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text('Notifications', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: t.ink)),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text(_error!, style: TextStyle(color: t.mute)))
                  : _items.isEmpty
                      ? Center(child: Text('No notifications yet.', style: TextStyle(color: t.mute)))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            final meta = item['metadata'];
                            final map = meta is Map ? Map<String, dynamic>.from(meta) : const <String, dynamic>{};
                            final image = '${map['imageUrl'] ?? ''}'.trim();
                            final read = item['markedAsRead'] == true;
                            return Material(
                              color: read ? t.bg : t.card,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => _open(item),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (image.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(right: 10),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: Image.network(image, width: 56, height: 56, fit: BoxFit.cover),
                                          ),
                                        ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('${item['title'] ?? 'Update'}', style: TextStyle(fontWeight: FontWeight.w700, color: t.ink)),
                                            const SizedBox(height: 4),
                                            Text('${item['body'] ?? map['body'] ?? ''}', style: TextStyle(color: t.mute, fontSize: 13)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}
