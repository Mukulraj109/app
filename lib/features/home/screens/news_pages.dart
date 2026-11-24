import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../api/api_client.dart';
import '../../../shared_widgets/app_nav.dart';
import '../../../theme/home_tokens.dart';
import '../home_store.dart';

/// Same discover filters as web LearnPages / backend `discoverFilter`.
const kDiscoverFilters = <MapEntry<String, String>>[
  MapEntry('all', 'All'),
  MapEntry('immigration', 'Immigration'),
  MapEntry('ai', 'AI'),
  MapEntry('tips', 'Tips'),
  MapEntry('industry', 'Industry'),
  MapEntry('blogs', 'Blogs'),
  MapEntry('updates', 'Updates'),
];

/// Absolute http(s) as-is; `/blog/...` resolves against the website origin.
/// Callers: NewsArticlePage Open article. No duplicate helper elsewhere.
String resolveDiscoverHref(
  String href, {
  String webOrigin = 'https://firststepjob.com',
}) {
  final raw = href.trim();
  if (raw.isEmpty) return '';
  if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
  final origin = webOrigin.trim().replaceAll(RegExp(r'/+$'), '');
  if (raw.startsWith('/')) return '$origin$raw';
  return '$origin/$raw';
}

Future<void> _openDiscoverHref(
  String href, {
  String webOrigin = 'https://firststepjob.com',
}) async {
  final resolved = resolveDiscoverHref(href, webOrigin: webOrigin);
  if (resolved.isEmpty) return;
  final uri = Uri.tryParse(resolved);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<void> openNewsFeed(
  BuildContext context, {
  NewsCard? focus,
  List<NewsCard>? liveCards,
  ApiClient? api,
}) {
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
      final h = MediaQuery.sizeOf(sheet).height * 0.8;
      return SizedBox(
        height: h,
        child: api == null
            ? NewsFeedPage(focus: focus, asSheet: true, liveCards: liveCards)
            : _DiscoverFeed(api: api, focus: focus),
      );
    },
  );
}

Future<void> openNewsArticle(
  BuildContext context,
  NewsCard card, {
  ApiClient? api,
  void Function(NewsCard updated)? onUpdated,
}) {
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
      final h = MediaQuery.sizeOf(sheet).height * 0.8;
      return SizedBox(
        height: h,
        child: NewsArticlePage(
          card: card,
          asSheet: true,
          api: api,
          onUpdated: onUpdated,
        ),
      );
    },
  );
}

class NewsFeedPage extends StatelessWidget {
  final NewsCard? focus;
  final bool asSheet;
  final List<NewsCard>? liveCards;

  const NewsFeedPage({
    super.key,
    this.focus,
    this.asSheet = false,
    this.liveCards,
  });

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final cards = liveCards ?? [
      if (focus != null) focus!,
      ...sampleNews.where((c) => c.title != focus?.title),
    ];

    Widget cardTile(NewsCard card) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: asSheet ? t.bg : t.card,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => openNewsArticle(context, card),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: t.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _CatChip(category: card.category, pastel: card.pastel),
                      if (card.saved) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.bookmark_rounded, size: 16, color: t.teal),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    card.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: t.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    card.readTime,
                    style: TextStyle(fontSize: 12.5, color: t.mute),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (asSheet) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'News',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: t.ink,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: t.mute),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              'Immigration first · then AI and industry',
              style: TextStyle(fontSize: 13, color: t.mute),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [for (final card in cards) cardTile(card)],
            ),
          ),
        ],
      );
    }

    return AppPageScaffold(
      title: 'News',
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Text(
            'Immigration first · then AI and industry',
            style: TextStyle(fontSize: 13, color: t.mute),
          ),
        ),
        for (final card in cards)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: cardTile(card),
          ),
      ],
    );
  }
}

/// Article sheet. Callers: openNewsArticle, Discover feed.
/// APIs: POST /api/me/discover/:id/save. User: android Play-ready Discover.
class NewsArticlePage extends StatefulWidget {
  final NewsCard card;
  final bool asSheet;
  final ApiClient? api;
  final void Function(NewsCard updated)? onUpdated;

  const NewsArticlePage({
    super.key,
    required this.card,
    this.asSheet = false,
    this.api,
    this.onUpdated,
  });

  @override
  State<NewsArticlePage> createState() => _NewsArticlePageState();
}

class _NewsArticlePageState extends State<NewsArticlePage> {
  late NewsCard _card;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _card = widget.card;
  }

  String get _webOrigin {
    final origin = widget.api?.config.safeWebAppOrigin;
    if (origin == null || origin.isEmpty) return 'https://firststepjob.com';
    // Marketing site hosts /blog paths; app subdomain is for the dashboard.
    if (origin.contains('app.firststepjob.com')) {
      return 'https://firststepjob.com';
    }
    return origin;
  }

  Future<void> _toggleSave() async {
    final api = widget.api;
    final id = _card.id.trim();
    if (api == null || id.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      final nextSaved = !_card.saved;
      await api.saveDiscoverPost(id, remove: !nextSaved);
      if (!mounted) return;
      final updated = _card.copyWith(saved: nextSaved);
      setState(() {
        _card = updated;
        _saving = false;
      });
      widget.onUpdated?.call(updated);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update saved article.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final resolved = resolveDiscoverHref(_card.href, webOrigin: _webOrigin);
    final canOpen = !_card.unavailable && resolved.isNotEmpty;
    final canSave = widget.api != null && _card.id.isNotEmpty && !_card.unavailable;

    final body = Padding(
      padding: EdgeInsets.fromLTRB(widget.asSheet ? 20 : 20, widget.asSheet ? 0 : 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CatChip(category: _card.category, pastel: _card.pastel),
          const SizedBox(height: 14),
          Text(
            _card.title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: t.ink,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _card.readTime,
            style: TextStyle(fontSize: 13, color: t.mute),
          ),
          const SizedBox(height: 18),
          Text(
            _card.unavailable
                ? 'No longer available'
                : _card.body.trim().isEmpty
                    ? 'This update has no extra text yet.'
                    : _card.body,
            style: TextStyle(
              fontSize: 15,
              height: 1.55,
              color: t.ink,
            ),
          ),
          if (canOpen || canSave) ...[
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (canOpen)
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: t.ctaBg,
                      foregroundColor: t.ctaInk,
                    ),
                    onPressed: () => _openDiscoverHref(
                      _card.href,
                      webOrigin: _webOrigin,
                    ),
                    child: const Text('Open article'),
                  ),
                if (canSave)
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _toggleSave,
                    icon: Icon(
                      _card.saved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      size: 18,
                    ),
                    label: Text(_card.saved ? 'Saved' : 'Save'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );

    if (widget.asSheet) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _card.category,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: t.ink,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: t.mute),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(child: body),
          ),
        ],
      );
    }

    return AppPageScaffold(
      title: _card.category,
      children: [body],
    );
  }
}

class _CatChip extends StatelessWidget {
  final String category;
  final String pastel;

  const _CatChip({required this.category, required this.pastel});

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final tone = switch (pastel) {
      'sky' => t.sky,
      'lavender' => t.lavender,
      'mint' => t.mint,
      'peach' => t.peach,
      _ => t.butter,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: tone.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        category,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: tone.fg,
        ),
      ),
    );
  }
}

class _DiscoverFeed extends StatefulWidget {
  const _DiscoverFeed({required this.api, this.focus});
  final ApiClient api;
  final NewsCard? focus;

  @override
  State<_DiscoverFeed> createState() => _DiscoverFeedState();
}

List<NewsCard> newsCardsFromDiscover(Map<String, dynamic> json) {
  final raw = json['posts'] ?? json['items'] ?? json['discover'];
  final cards = <NewsCard>[];
  if (raw is! List) return cards;
  for (final item in raw.whereType<Map>()) {
    final title = '${item['title'] ?? item['headline'] ?? ''}'.trim();
    if (title.isEmpty) continue;
    final unavailable = item['unavailable'] == true;
    cards.add(NewsCard(
      id: '${item['id'] ?? ''}'.trim(),
      category: unavailable
          ? 'Saved'
          : '${item['category'] ?? item['filter'] ?? 'News'}',
      pastel: cards.length.isEven ? 'sky' : 'mint',
      title: title,
      readTime: unavailable
          ? 'Unavailable'
          : '${item['readTime'] ?? item['read_time'] ?? '2 min'}',
      body: '${item['body'] ?? item['summary'] ?? item['excerpt'] ?? ''}'.trim(),
      href: unavailable ? '' : '${item['href'] ?? item['url'] ?? ''}'.trim(),
      unavailable: unavailable,
      saved: item['saved'] == true,
    ));
  }
  return cards;
}

class _DiscoverFeedState extends State<_DiscoverFeed> {
  List<NewsCard> _cards = const [];
  bool _loading = true;
  String? _error;
  String _filter = 'all';
  bool _hasNew = false;

  @override
  void initState() {
    super.initState();
    _load();
    _loadUnread();
  }

  Future<void> _loadUnread() async {
    try {
      final json = await widget.api.getDiscoverUnread();
      if (!mounted) return;
      setState(() {
        _hasNew = json['hasNew'] == true ||
            json['unread'] == true ||
            (json['count'] is num && (json['count'] as num) > 0);
      });
    } catch (_) {
      /* badge is optional */
    }
  }

  Future<void> _load({String? filter}) async {
    final next = filter ?? _filter;
    setState(() {
      _loading = true;
      _error = null;
      _filter = next;
    });
    try {
      final json = await widget.api.getDiscover(filter: next);
      if (!mounted) return;
      setState(() {
        _cards = newsCardsFromDiscover(json);
        _loading = false;
      });
      widget.api.markDiscoverViewed();
      if (mounted) setState(() => _hasNew = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load news.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    if (_loading && _cards.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _cards.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: kDiscoverFilters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final entry = kDiscoverFilters[i];
                      final selected = entry.key == _filter;
                      return FilterChip(
                        label: Text(
                          entry.key == 'all' && _hasNew
                              ? '${entry.value} · new'
                              : entry.value,
                        ),
                        selected: selected,
                        onSelected: (_) {
                          if (!selected) _load(filter: entry.key);
                        },
                        selectedColor: t.teal.withOpacity(0.15),
                        checkmarkColor: t.teal,
                        labelStyle: TextStyle(
                          color: selected ? t.teal : t.ink,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 12.5,
                        ),
                      );
                    },
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _openSubmitSheet(context),
                child: const Text('Share'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _DiscoverList(
                  focus: widget.focus,
                  cards: _cards,
                  api: widget.api,
                  onUpdated: (updated) {
                    setState(() {
                      _cards = [
                        for (final card in _cards)
                          if (card.id == updated.id) updated else card,
                      ];
                    });
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _openSubmitSheet(BuildContext context) async {
    final titleCtrl = TextEditingController();
    final summaryCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    final t = HomeTokens.of(context);
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: !kIsWeb && Platform.isIOS,
      backgroundColor: t.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheet) {
        final inset = MediaQuery.viewInsetsOf(sheet).bottom;
        final home = !kIsWeb && Platform.isIOS
            ? MediaQuery.viewPaddingOf(sheet).bottom
            : 0.0;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + inset + home),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Share a discovery',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: t.ink,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: summaryCtrl,
                decoration: const InputDecoration(labelText: 'Short summary'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: bodyCtrl,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Details'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: t.ctaBg,
                  foregroundColor: t.ctaInk,
                ),
                onPressed: () {
                  if (titleCtrl.text.trim().isEmpty) return;
                  Navigator.pop(sheet, true);
                },
                child: const Text('Submit for review'),
              ),
            ],
          ),
        );
      },
    );
    final title = titleCtrl.text.trim();
    final summary = summaryCtrl.text.trim();
    final body = bodyCtrl.text.trim();
    titleCtrl.dispose();
    summaryCtrl.dispose();
    bodyCtrl.dispose();
    if (submitted != true || !mounted) return;
    try {
      await widget.api.submitDiscoverPost({
        'title': title,
        'summary': summary,
        'body': body,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submitted for review.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not submit. Try again.')),
      );
    }
  }
}

class _DiscoverList extends StatelessWidget {
  const _DiscoverList({
    required this.cards,
    required this.api,
    this.focus,
    this.onUpdated,
  });

  final List<NewsCard> cards;
  final ApiClient api;
  final NewsCard? focus;
  final void Function(NewsCard updated)? onUpdated;

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final ordered = [
      if (focus != null) focus!,
      ...cards.where((c) => c.title != focus?.title),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        for (final card in ordered)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: t.bg,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => openNewsArticle(
                  context,
                  card,
                  api: api,
                  onUpdated: onUpdated,
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: t.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _CatChip(
                            category: card.category,
                            pastel: card.pastel,
                          ),
                          if (card.saved) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.bookmark_rounded,
                              size: 16,
                              color: t.teal,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        card.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: t.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        card.readTime,
                        style: TextStyle(fontSize: 12.5, color: t.mute),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
