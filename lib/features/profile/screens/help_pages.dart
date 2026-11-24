import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../api/profile_models.dart';
import '../../../auth/auth_controller.dart';
import '../../../shared_widgets/app_nav.dart';
import '../../../theme/home_tokens.dart';
import '../content/landing_faqs.dart';
import '../content/legal_copy.dart';
import '../profile_store.dart';
import 'profile_screens.dart'
    show
        profileSheetGrabber,
        profileSheetShell,
        shareProfileDocument,
        showProfileBottomSheet,
        showProfileToast;

Future<void> openFaq(BuildContext context) {
  return showProfileBottomSheet(
    context,
    heightFactor: 0.85,
    child: const FaqPage(),
  );
}

Future<void> openHolidayCalendar(
  BuildContext context, {
  AuthController? auth,
}) {
  return showProfileBottomSheet(
    context,
    heightFactor: 0.85,
    child: HolidayCalendarPage(auth: auth),
  );
}

Future<void> openTermsPrivacy(BuildContext context) {
  return showProfileBottomSheet(
    context,
    heightFactor: 0.85,
    child: const TermsPrivacyPage(),
  );
}

Future<void> openPlanIncluded(BuildContext context, ProfileStore store) {
  return showProfileBottomSheet(
    context,
    heightFactor: 0.85,
    child: PlanIncludedPage(store: store, asSheet: true),
  );
}

Future<void> openDocumentPreview(
  BuildContext context, {
  required String title,
  String subtitle = 'PDF',
  bool emptyUpload = false,
  ProfileDoc? doc,
  AuthController? auth,
}) {
  return showProfileBottomSheet(
    context,
    child: DocumentPreviewPage(
      title: title,
      subtitle: subtitle,
      emptyUpload: emptyUpload,
      doc: doc,
      auth: auth,
      asSheet: true,
    ),
  );
}

class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  String _category = 'All';

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final items = _category == 'All'
        ? landingFaqs
        : landingFaqs.where((f) => f.category == _category).toList();
    return profileSheetShell(
      context: context,
      title: 'FAQ',
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final cat in faqCategories) ...[
                  FilterChip(
                    label: Text(cat),
                    selected: _category == cat,
                    onSelected: (_) => setState(() => _category = cat),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Text(
              'No questions in this category.',
              style: TextStyle(color: t.mute, fontSize: 13),
            ),
          ),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                backgroundColor: t.card,
                collapsedBackgroundColor: t.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: t.line),
                ),
                collapsedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: t.line),
                ),
                title: Text(
                  item.question,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: t.ink,
                  ),
                ),
                subtitle: Text(
                  item.category,
                  style: TextStyle(fontSize: 11.5, color: t.mute),
                ),
                children: [
                  Text(
                    item.answer,
                    style: TextStyle(fontSize: 14, height: 1.45, color: t.mute),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class HolidayCalendarPage extends StatefulWidget {
  const HolidayCalendarPage({super.key, this.auth});

  final AuthController? auth;

  @override
  State<HolidayCalendarPage> createState() => _HolidayCalendarPageState();
}

class _HolidayCalendarPageState extends State<HolidayCalendarPage> {
  List<CalendarHoliday> _holidays = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = widget.auth;
    if (auth == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final rows = await auth.api.getCalendar();
      if (mounted) setState(() => _holidays = rows);
    } catch (_) {
      /* keep empty */
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _label(CalendarHoliday h) {
    final key = h.dateKey.trim();
    if (key.isEmpty) return '—';
    final dt = DateTime.tryParse(key);
    if (dt == null) return key;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return profileSheetShell(
      context: context,
      title: 'Holiday calendar',
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Text(
            'US market holidays when our team may pause applications. '
            'You will see a notice on Home when the schedule changes.',
            style: TextStyle(fontSize: 14, height: 1.45, color: t.mute),
          ),
        ),
        const SizedBox(height: 8),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          Material(
            color: t.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: t.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                if (_holidays.isEmpty)
                  ListTile(
                    title: Text(
                      'No holidays listed yet.',
                      style: TextStyle(color: t.mute),
                    ),
                  )
                else
                  for (final h in _holidays)
                    ListTile(
                      title: Text(
                        h.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: t.ink,
                        ),
                      ),
                      trailing: Text(_label(h), style: TextStyle(color: t.mute)),
                    ),
              ],
            ),
          ),
      ],
    );
  }
}

class TermsPrivacyPage extends StatelessWidget {
  const TermsPrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return profileSheetShell(
      context: context,
      title: 'Terms & privacy',
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(
            'Shown in the app — same content as firststepjob.com/terms and /privacypolicy.',
            style: TextStyle(fontSize: 12.5, height: 1.4, color: t.mute),
          ),
        ),
        _LegalHeader(title: 'Terms of use', t: t),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text(
            termsLead,
            style: TextStyle(fontSize: 14, height: 1.45, color: t.mute),
          ),
        ),
        for (final section in termsSections)
          _LegalExpandable(section: section, t: t),
        const SizedBox(height: 8),
        _LegalHeader(title: 'Privacy policy', t: t),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(
            'Effective Date: $privacyEffectiveDate',
            style: TextStyle(fontSize: 12.5, color: t.mute),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text(
            privacyIntro,
            style: TextStyle(fontSize: 14, height: 1.45, color: t.mute),
          ),
        ),
        for (final section in privacySections)
          _LegalExpandable(section: section, t: t),
      ],
    );
  }
}

class _LegalHeader extends StatelessWidget {
  final String title;
  final HomeTokens t;

  const _LegalHeader({required this.title, required this.t});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: t.ink,
        ),
      ),
    );
  }
}

class _LegalExpandable extends StatelessWidget {
  final LegalSection section;
  final HomeTokens t;

  const _LegalExpandable({required this.section, required this.t});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          backgroundColor: t.card,
          collapsedBackgroundColor: t.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: t.line),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: t.line),
          ),
          title: Text(
            section.title,
            style: TextStyle(fontWeight: FontWeight.w600, color: t.ink),
          ),
          children: [
            for (final p in section.paragraphs) ...[
              Text(
                p,
                style: TextStyle(fontSize: 14, height: 1.45, color: t.mute),
              ),
              const SizedBox(height: 8),
            ],
            if (section.bullets.isNotEmpty)
              ...section.bullets.map(
                (b) => Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('•  ', style: TextStyle(color: t.mute)),
                      Expanded(
                        child: Text(
                          b,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: t.mute,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PlanIncludedPage extends StatelessWidget {
  final ProfileStore store;
  final bool asSheet;

  const PlanIncludedPage({super.key, required this.store, this.asSheet = false});

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final c = store.content;

    final details = store.planDetails;
    final rows = <Widget>[
      if (details != null && details.description.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            details.description,
            style: TextStyle(fontSize: 13.5, height: 1.45, color: t.mute),
          ),
        ),
      if (details != null)
        for (final feature in details.features)
          _IncludedRow(
            t: t,
            pastel: t.lavender,
            icon: Icons.check_circle_outline,
            title: feature,
            subtitle: '',
          ),
      _IncludedRow(
        t: t,
        pastel: t.mint,
        icon: Icons.assignment_outlined,
        title: 'Applications by your partner',
        subtitle: 'Real people apply for you',
      ),
      if (c.whatsapp)
        _IncludedRow(
          t: t,
          pastel: t.mint,
          icon: Icons.chat_bubble_outline,
          title: 'WhatsApp group',
          subtitle: 'You, your partner & the team',
        ),
      ...store.planBenefits.map(
        (chip) => _IncludedRow(
          t: t,
          pastel: _chipPastel(t, chip.pastel),
          icon: Icons.star_outline,
          title: chip.title,
          subtitle: chip.status,
          chipLabel: chip.status,
        ),
      ),
    ];

    final footer =
        'Everything here ends on ${c.planUseBy.isEmpty ? "your plan end date" : c.planUseBy}. '
        'Payment: paid in full · invoice in My documents.';

    if (asSheet) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          profileSheetGrabber(t),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Text(
              c.planName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: t.ink,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(
              c.planDates,
              style: TextStyle(fontSize: 13, color: t.mute),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              children: [
                ...rows,
                const SizedBox(height: 12),
                Text(
                  footer,
                  style: TextStyle(fontSize: 12.5, height: 1.45, color: t.mute),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: t.ink,
                      side: BorderSide(color: t.line),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return AppPageScaffold(
      title: "What's included",
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(c.planDates, style: TextStyle(color: t.mute)),
              const SizedBox(height: 12),
              ...rows,
              const SizedBox(height: 12),
              Text(footer, style: TextStyle(fontSize: 12.5, color: t.mute)),
            ],
          ),
        ),
      ],
    );
  }
}

Pastel _chipPastel(HomeTokens t, String key) {
  return switch (key) {
    'pch' => t.peach,
    'sky' => t.sky,
    'but' => t.butter,
    _ => t.lavender,
  };
}

class _IncludedRow extends StatelessWidget {
  final HomeTokens t;
  final Pastel pastel;
  final IconData icon;
  final String title;
  final String subtitle;
  final String? chipLabel;

  const _IncludedRow({
    required this.t,
    required this.pastel,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.chipLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: pastel.bg,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: pastel.fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: t.ink,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12.5, color: t.mute),
                ),
              ],
            ),
          ),
          if (chipLabel != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: pastel.bg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                chipLabel!,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: pastel.fg,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class DocumentPreviewPage extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool emptyUpload;
  final bool asSheet;
  final ProfileDoc? doc;
  final AuthController? auth;

  const DocumentPreviewPage({
    super.key,
    required this.title,
    this.subtitle = 'PDF',
    this.emptyUpload = false,
    this.asSheet = false,
    this.doc,
    this.auth,
  });

  @override
  State<DocumentPreviewPage> createState() => _DocumentPreviewPageState();
}

class _DocumentPreviewPageState extends State<DocumentPreviewPage> {
  bool _opening = false;

  Future<void> _openPreview() async {
    final item = widget.doc;
    final auth = widget.auth;
    if (item == null || !item.canDownload || item.id.isEmpty || auth == null) {
      showProfileToast(
        context,
        auth == null
            ? 'Sign in again to preview this document.'
            : 'This document is not ready to preview yet.',
      );
      return;
    }
    setState(() => _opening = true);
    try {
      final url = await auth.api.previewAttachmentUrl(
        attachmentId: item.id,
        attachmentTitle: item.title,
      );
      final uri = Uri.tryParse(url);
      if (uri == null || !await canLaunchUrl(uri)) {
        if (mounted) {
          showProfileToast(context, 'Could not open this document.');
        }
        return;
      }
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    } catch (_) {
      if (mounted) {
        showProfileToast(context, 'Could not open this document.');
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final canPreview = widget.doc?.canDownload == true;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.emptyUpload)
          Text(
            'Pick a PDF or Word file from your phone. We use it to improve job picks.',
            style: TextStyle(fontSize: 14, color: t.mute),
          )
        else ...[
          Text(widget.subtitle, style: TextStyle(fontSize: 13, color: t.mute)),
          const SizedBox(height: 16),
          Container(
            height: 240,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: t.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: t.line),
            ),
            child: Text(
              canPreview
                  ? 'Opens a short-lived preview link — same secure preview as the website.'
                  : 'Preview opens here once the file is available.',
              style: TextStyle(color: t.mute, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (!widget.emptyUpload) ...[
          FilledButton.icon(
            onPressed: canPreview && !_opening ? _openPreview : null,
            icon: _opening
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.open_in_browser, size: 18),
            label: Text(_opening ? 'Opening…' : 'View document'),
            style: FilledButton.styleFrom(
              backgroundColor: t.navy,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              final item = widget.doc;
              if (item != null) {
                shareProfileDocument(context, doc: item, auth: widget.auth);
                return;
              }
              showProfileToast(
                context,
                'This document is not ready to download yet.',
              );
            },
            icon: const Icon(Icons.ios_share, size: 18),
            label: const Text('Share / save'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ],
    );

    if (widget.asSheet) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          profileSheetGrabber(t),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Text(
              widget.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: t.ink,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [body],
            ),
          ),
        ],
      );
    }

    return AppPageScaffold(
      title: widget.title,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: body,
        ),
      ],
    );
  }
}