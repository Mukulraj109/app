import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../api/api_client.dart';
import '../../../auth/auth_controller.dart';
import '../../../shared_widgets/app_nav.dart';
import '../../../state/app_state.dart';
import '../../../theme/home_tokens.dart';
import 'help_pages.dart';
import '../profile_store.dart';
import '../widgets/avatar_mark.dart';

Future<void> shareProfileDocument(
  BuildContext context, {
  required ProfileDoc doc,
  AuthController? auth,
}) async {
  if (!doc.canDownload || doc.id.isEmpty || auth == null) {
    showProfileToast(
      context,
      auth == null
          ? 'Sign in again to download this document.'
          : 'This document is not ready to download yet.',
    );
    return;
  }
  try {
    showProfileToast(context, 'Preparing download…');
    final file = await auth.api.downloadDocument(doc.id);
    final safeName = file.fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final path = '${Directory.systemTemp.path}/$safeName';
    await File(path).writeAsBytes(file.bytes, flush: true);
    await Share.shareXFiles([XFile(path)], subject: doc.title, text: doc.title);
  } catch (_) {
    if (context.mounted) {
      showProfileToast(context, 'Could not download this document.');
    }
  }
}

Future<void> openBenefitAction(
  BuildContext context,
  ProfileStore store,
  PlanBenefitChip chip,
) async {
  final url = chip.formUrl?.trim();
  if (url != null && url.isNotEmpty) {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
  }
  if (chip.formKey == 'scoutx') {
    await launchUrl(
      Uri.parse('https://firststepjob.com/scoutx'),
      mode: LaunchMode.externalApplication,
    );
    return;
  }
  if (chip.formKey == 'portfolio' && store.content.portfolioReady) {
    openExternal('https://meera.firststep.site');
    return;
  }
  if (!context.mounted) return;
  // Honest copy — no fake "opens form" when formUrl is missing.
  showProfileToast(
    context,
    switch (chip.formKey) {
      'mock' =>
          'Mock interview booking is not linked for your plan yet. Chat with your AIC on WhatsApp.',
      'linkedin' =>
          'LinkedIn workshop booking is not linked for your plan yet. Ask your AIC.',
      'portfolio' =>
          'Portfolio details are not ready yet. Check back after your AIC uploads them.',
      _ => 'This benefit is not available to open in the app yet.',
    },
  );
}

void showProfileToast(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(milliseconds: 2800),
    ),
  );
}

/// Profile sheets use [HomeTokens] for inputs/chips — not app-wide indigo/coral.
ThemeData profileSheetTheme(BuildContext context) {
  final t = HomeTokens.of(context);
  final base = Theme.of(context);
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: t.line),
  );
  return base.copyWith(
    splashColor: t.teal.withValues(alpha: 0.08),
    highlightColor: t.teal.withValues(alpha: 0.05),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: t.teal,
      selectionColor: t.tealSoft,
      selectionHandleColor: t.teal,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: t.bg,
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: t.teal, width: 1.5),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: t.card,
      selectedColor: t.tealSoft,
      disabledColor: t.bg,
      labelStyle: TextStyle(fontSize: 13, color: t.ink, fontWeight: FontWeight.w500),
      secondaryLabelStyle: TextStyle(fontSize: 13, color: t.navy),
      checkmarkColor: t.teal,
      side: BorderSide(color: t.line),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
  );
}

InputDecoration profileFieldDecoration(
  HomeTokens t, {
  BorderRadius? radius,
  String? hint,
}) {
  final r = radius ?? BorderRadius.circular(12);
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: t.mute),
    filled: true,
    fillColor: t.bg,
    border: OutlineInputBorder(borderRadius: r, borderSide: BorderSide(color: t.line)),
    enabledBorder: OutlineInputBorder(borderRadius: r, borderSide: BorderSide(color: t.line)),
    focusedBorder: OutlineInputBorder(
      borderRadius: r,
      borderSide: BorderSide(color: t.teal, width: 1.5),
    ),
  );
}

/// Profile modal sheets: grab handle, safe area, configurable height (default 80%).
/// Keyboard: lift sheet via [MediaQuery.viewInsets] padding only (do not also
/// subtract insets from max height — children must not add bottom viewInsets).
Future<T?> showProfileBottomSheet<T>(
  BuildContext context, {
  required Widget child,
  double heightFactor = 0.8,
}) {
  final t = HomeTokens.of(context);
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: t.card,
    isScrollControlled: true,
    useSafeArea: true,
    sheetAnimationStyle: const AnimationStyle(
      duration: Duration(milliseconds: 420),
      reverseDuration: Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (sheetContext) {
      final mq = MediaQuery.of(sheetContext);
      final maxH = (mq.size.height * heightFactor).clamp(
        200.0,
        mq.size.height - mq.viewPadding.top - 16,
      );
      return Theme(
        data: profileSheetTheme(sheetContext),
        child: Padding(
          padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxH),
              child: child,
            ),
          ),
        ),
      );
    },
  );
}

Future<void> dismissProfileSheetKeyboard(BuildContext context) async {
  FocusScope.of(context).unfocus();
  FocusManager.instance.primaryFocus?.unfocus();
  await Future<void>.delayed(Duration.zero);
}

Future<void> closeProfileSheet(BuildContext context, [dynamic result]) async {
  await dismissProfileSheetKeyboard(context);
  if (context.mounted) Navigator.pop(context, result);
}

/// Shared chrome for profile bottom sheets (grabber + title + scroll body).
Widget profileSheetShell({
  required BuildContext context,
  required String title,
  String? subtitle,
  required List<Widget> children,
}) {
  final t = HomeTokens.of(context);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      profileSheetGrabber(t),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: t.ink,
          ),
        ),
      ),
      if (subtitle != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: t.mute),
          ),
        )
      else
        const SizedBox(height: 8),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: children,
        ),
      ),
    ],
  );
}

Widget profileSheetGrabber(HomeTokens t) {
  return Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 6),
    child: Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: t.line,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    ),
  );
}

Future<void> _openWhatsAppTicket({
  required int selectedIndex,
  required String message,
}) async {
  final reason = ProfileStore.reasons[selectedIndex].$2;
  final extra = message.trim();
  final buf = StringBuffer()
    ..writeln('FirstStep support ticket')
    ..writeln('Reason: $reason');
  if (extra.isNotEmpty) buf.writeln(extra);
  if (extra.isNotEmpty) buf.writeln(extra);
  final base = Uri.parse(AppUrls.whatsapp);
  final uri = base.replace(queryParameters: {'text': buf.toString()});
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<void> openAvatarSheet(BuildContext context, ProfileStore store) {
  final t = HomeTokens.of(context);
  return showProfileBottomSheet(
    context,
    child: AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              profileSheetGrabber(t),
              const SizedBox(height: 8),
                  Text(
                    'Profile photo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: t.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Upload a photo or pick one of ours.',
                    style: TextStyle(fontSize: 13, color: t.mute),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => showProfileToast(
                            context,
                            'Your Google photo shows when you sign in. Pick a pattern below to change the look.',
                          ),
                          icon: const Icon(Icons.photo_camera_outlined, size: 18),
                          label: const Text('Take photo'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => showProfileToast(
                            context,
                            'Your Google photo shows when you sign in. Pick a pattern below to change the look.',
                          ),
                          icon: const Icon(Icons.image_outlined, size: 18),
                          label: const Text('Choose photo'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Or pick an avatar',
                    style: TextStyle(fontSize: 12.5, color: t.mute),
                  ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 8),
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final a in ProfileStore.avatars)
                          GestureDetector(
                            onTap: () => store.setAvatar(a.$1, a.$2),
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: store.avatarKind == a.$1 &&
                                          store.avatarBg == a.$2
                                      ? t.teal
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: AvatarMark(
                                kind: a.$1,
                                pastelKey: a.$2,
                                initial: store.content.initial,
                                size: 52,
                                // Pattern picker previews ignore network photo.
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              store.removePhoto();
                              Navigator.pop(context);
                            },
                            child: const Text('Remove photo'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: t.navy,
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Done'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

Future<void> openTicketsSheet(
  BuildContext context,
  ProfileStore store, {
  AuthController? auth,
}) {
  final t = HomeTokens.of(context);
  return showProfileBottomSheet(
    context,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          profileSheetGrabber(t),
          const SizedBox(height: 8),
          Text(
            'Support',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: t.ink,
            ),
          ),
          Text(
            'Your tickets. Replies come on WhatsApp; the status updates here.',
            style: TextStyle(fontSize: 13, color: t.mute),
          ),
          const SizedBox(height: 12),
          Expanded(child: _TicketList(store: store, auth: auth)),
        ],
      ),
    ),
  );
}

class _TicketList extends StatefulWidget {
  const _TicketList({required this.store, this.auth});
  final ProfileStore store;
  final AuthController? auth;

  @override
  State<_TicketList> createState() => _TicketListState();
}

class _TicketListState extends State<_TicketList> {
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final auth = widget.auth;
    if (auth == null) return;
    _loading = true;
    auth.api.getSupportTickets().then((tickets) {
      widget.store.applyRemote(ticketsSummary: tickets);
      if (mounted) setState(() => _loading = false);
    }).catchError((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    if (_loading) return const Center(child: CircularProgressIndicator());
    final tickets = widget.store.tickets;
    return ListView(
      padding: const EdgeInsets.only(bottom: 8),
      children: [
        if (tickets.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16, top: 8),
            child: Text(
              'No tickets yet. Raise one and we reply on WhatsApp on weekdays.',
              style: TextStyle(fontSize: 13.5, color: t.mute),
            ),
          ),
        for (final tk in tickets)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(tk.reason, style: TextStyle(fontWeight: FontWeight.w600, color: t.ink, fontSize: 14)),
            subtitle: Text('${tk.number} · "${tk.preview}" · ${tk.when}', style: TextStyle(fontSize: 12.5, color: t.mute)),
            trailing: _StatusChip(status: tk.status),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: t.navy),
            onPressed: () {
              Navigator.pop(context);
              openTicketSheet(context, widget.store, auth: widget.auth);
            },
            child: const Text('Raise a new ticket'),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final p = status == 'Open'
        ? t.butter
        : status == 'Replied'
            ? t.sky
            : t.mint;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: p.fg,
        ),
      ),
    );
  }
}

Future<void> openTicketSheet(
  BuildContext context,
  ProfileStore store, {
  int preselect = -1,
  AuthController? auth,
}) {
  return showProfileBottomSheet(
    context,
    child: _RaiseTicketSheet(
      store: store,
      preselect: preselect,
      auth: auth,
    ),
  );
}

Pastel _reasonPastel(HomeTokens t, String key) {
  return switch (key) {
    'lav' => t.lavender,
    'pch' => t.peach,
    'but' => t.butter,
    'sky' => t.sky,
    'mint' => t.mint,
    _ => Pastel(t.bg, t.ink),
  };
}

IconData _reasonIcon(String title) {
  return switch (title) {
    'Change my details' => Icons.person_outline,
    'Change my target roles' => Icons.work_outline,
    'Add a company to avoid' => Icons.block,
    'Plan & billing' => Icons.credit_card_outlined,
    'Application question' => Icons.description_outlined,
    _ => Icons.chat_bubble_outline,
  };
}

class _TicketReasonCard extends StatelessWidget {
  final String pastelKey;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _TicketReasonCard({
    required this.pastelKey,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final pastel = _reasonPastel(t, pastelKey);
    return Material(
      color: t.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? t.ctaBg : t.line,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: t.ctaBg.withValues(alpha: 0.35),
                      blurRadius: 0,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: pastel.bg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  _reasonIcon(title),
                  size: 18,
                  color: pastel.fg,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: t.ink,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: t.mute),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single-field editor: controller owned by [State], unfocus before pop.
class _ProfileTextFieldSheet extends StatefulWidget {
  const _ProfileTextFieldSheet({
    required this.title,
    this.subtitle,
    required this.initialValue,
    this.maxLines = 1,
    required this.onSave,
  });

  final String title;
  final String? subtitle;
  final String initialValue;
  final int maxLines;
  /// `null` = saved OK; non-null = error toast message (stay open).
  final Future<String?> Function(String trimmed) onSave;

  @override
  State<_ProfileTextFieldSheet> createState() => _ProfileTextFieldSheetState();
}

class _ProfileTextFieldSheetState extends State<_ProfileTextFieldSheet> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final err = await widget.onSave(_controller.text.trim());
    if (!mounted) return;
    setState(() => _saving = false);
    if (err != null) {
      showProfileToast(context, err);
      return;
    }
    await closeProfileSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            profileSheetGrabber(t),
            const SizedBox(height: 8),
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: t.ink,
              ),
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                widget.subtitle!,
                style: TextStyle(fontSize: 13, color: t.mute),
              ),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _controller,
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                      maxLines: widget.maxLines,
                      style: TextStyle(color: t.ink, fontSize: 15),
                      cursorColor: t.teal,
                      scrollPadding: const EdgeInsets.only(bottom: 120),
                      onSubmitted: (_) => _save(),
                      decoration: profileFieldDecoration(t),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: t.navy,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _saving ? null : _save,
                        child: Text(_saving ? 'Saving…' : 'Save'),
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

class _RaiseTicketSheet extends StatefulWidget {
  const _RaiseTicketSheet({
    required this.store,
    this.preselect = -1,
    this.auth,
  });

  final ProfileStore store;
  final int preselect;
  final AuthController? auth;

  @override
  State<_RaiseTicketSheet> createState() => _RaiseTicketSheetState();
}

class _RaiseTicketSheetState extends State<_RaiseTicketSheet> {
  late int _selected;
  late final TextEditingController _message;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.preselect;
    _message = TextEditingController(
      text: widget.preselect == 2
          ? "Please don't apply to Meta or Oracle."
          : '',
    );
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selected < 0 || _submitting) return;
    setState(() => _submitting = true);
    final reason = ProfileStore.reasons[_selected].$2;
    final detail = _message.text.trim();
    final desc = [reason, if (detail.isNotEmpty) detail].join(' — ');
    final auth = widget.auth;
    final store = widget.store;
    final messageCopy = _message.text;

    try {
      if (auth != null) {
        await auth.api.createSupportTicket(
          description: desc,
          reason: reason,
        );
        try {
          final tickets = await auth.api.getSupportTickets();
          store.applyRemote(ticketsSummary: tickets);
        } catch (_) {}
        if (mounted) {
          showProfileToast(context, 'Ticket submitted. We reply on weekdays.');
        }
      } else {
        await _openWhatsAppTicket(
          selectedIndex: _selected,
          message: messageCopy,
        );
      }
      if (mounted) await closeProfileSheet(context);
    } catch (_) {
      if (mounted) {
        showProfileToast(context, 'Could not submit ticket. Try again.');
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final auth = widget.auth;
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            profileSheetGrabber(t),
            const SizedBox(height: 8),
            Text(
              'Raise a ticket',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: t.ink,
              ),
            ),
            Text(
              'What do you need help with?',
              style: TextStyle(fontSize: 13, color: t.mute),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  for (var i = 0; i < ProfileStore.reasons.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    _TicketReasonCard(
                      pastelKey: ProfileStore.reasons[i].$1,
                      title: ProfileStore.reasons[i].$2,
                      subtitle: ProfileStore.reasons[i].$3,
                      selected: _selected == i,
                      onTap: () => setState(() => _selected = i),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: _message,
                    maxLines: 3,
                    scrollPadding: const EdgeInsets.only(bottom: 120),
                    style: TextStyle(fontSize: 14, color: t.ink),
                    cursorColor: t.teal,
                    decoration: profileFieldDecoration(
                      t,
                      radius: BorderRadius.circular(14),
                      hint: 'Tell us a bit more (optional)…',
                    ).copyWith(contentPadding: const EdgeInsets.all(14)),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: t.wa,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: t.wa.withValues(alpha: 0.45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed:
                          _selected < 0 || _submitting ? null : _submit,
                      icon: Icon(
                        auth != null ? Icons.send_outlined : Icons.chat,
                        size: 18,
                      ),
                      label: Text(
                        auth != null
                            ? 'Submit ticket'
                            : 'Continue in WhatsApp',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      auth != null
                          ? 'We review tickets on weekdays. Add detail above if helpful.'
                          : 'Opens WhatsApp with your message ready. Add screenshots there.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.5, color: t.mute),
                    ),
                  ),
                  if (auth == null && widget.store.content.whatsapp)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Center(
                        child: Text(
                          'Faster? Message your WhatsApp group.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12.5, color: t.mute),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String? _appProfileFieldKey(String title) {
  return switch (title) {
    'Location' => 'location',
    'Tech stack' => 'tech',
    'Roles of interest' => 'rolesOfInterest',
    'News topics' => 'newsTopics',
    'Daily learning time' => 'learningTime',
    _ => null,
  };
}

Future<void> openDisplayNameSheet(
  BuildContext context, {
  required AuthController auth,
  ProfileStore? store,
}) {
  return showProfileBottomSheet<void>(
    context,
    heightFactor: 0.38,
    child: _ProfileTextFieldSheet(
      title: 'Display name',
      subtitle: 'Shown on your Profile. Does not change your Google account.',
      initialValue: auth.sessionUser?.displayName ?? '',
      onSave: (name) async {
        if (name.isEmpty) return 'Enter a name.';
        try {
          await auth.api.patchProfile(displayName: name);
          auth.updateSessionDisplayName(name);
          store?.applySessionUser(auth.sessionUser);
          return null;
        } catch (_) {
          return 'Could not update name. Try again.';
        }
      },
    ),
  );
}

Future<void> openEditSheet(
  BuildContext context,
  ProfileStore store,
  String title, {
  AuthController? auth,
}) {
  final multiLine = title == 'Tech stack' || title == 'News topics';
  return showProfileBottomSheet<void>(
    context,
    heightFactor: multiLine ? 0.48 : 0.38,
    child: _ProfileTextFieldSheet(
      title: title,
      subtitle: 'Changes your news, job picks and learning only.',
      initialValue: store.prefValue(title),
      maxLines: multiLine ? 4 : 1,
      onSave: (value) async {
        final key = _appProfileFieldKey(title);
        if (auth != null && key != null) {
          try {
            await auth.api.putAppProfile({key: value});
            store.updatePref(title, value);
            return null;
          } catch (_) {
            return 'Could not save. Try again.';
          }
        }
        store.updatePref(title, value);
        return null;
      },
    ),
  );
}

Future<void> openNotifications(
  BuildContext context, {
  AuthController? auth,
  AppState? appState,
}) {
  // Callers: SettingsHelpPage. Busts Home via appState.requestHomeRefresh.
  return showProfileBottomSheet<void>(
    context,
    heightFactor: 0.85,
    child: NotificationsPage(auth: auth, appState: appState),
  );
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key, this.auth, this.appState});

  final AuthController? auth;
  final AppState? appState;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  bool _paid = false;
  bool _whatsappConfirmed = false;
  bool _whatsappRequested = false;
  final Map<String, bool> _prefs = {
    'aiNews': true,
    'jobTips': true,
    'industry': true,
    'learning': true,
    'jobUpdates': true,
  };
  final Map<String, Map<String, bool>> _notices = {};
  String _emailLabel = 'Email';

  static const _groups = <(String, String)>[
    ('applications', 'Applications'),
    ('interviews', 'Interviews'),
    ('payment', 'Payment'),
    ('planAccount', 'Plan and account'),
    ('dailyEngagement', 'Daily engagement'),
    ('progress', 'Progress'),
    ('feedback', 'Feedback'),
    ('news', 'News'),
    ('adminBroadcast', 'From FirstStep'),
  ];

  static const _lockedIds = {
    'applications',
    'interviews',
    'payment',
    'planAccount',
  };

  static const _prefLabels = <(String, String)>[
    ('aiNews', 'AI news'),
    ('jobTips', 'Job search tips'),
    ('industry', 'Industry updates'),
    ('learning', 'Learning'),
    ('jobUpdates', 'Job updates'),
  ];

  @override
  void initState() {
    super.initState();
    _emailLabel = widget.auth?.sessionUser?.email.isNotEmpty == true
        ? widget.auth!.sessionUser!.email
        : 'Email';
    _load();
  }

  static String _deviceTimezone() => deviceTimezone();

  Map<String, bool> _defaultChannels() => {
        'inApp': true,
        'email': true,
        'push': true,
        'whatsapp': true,
      };

  Future<void> _load() async {
    final auth = widget.auth;
    if (auth == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final raw = await auth.api.getSettings();
      if (!mounted) return;
      _applySettingsBody(raw);
      setState(() => _loading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'Could not load notification settings.';
      });
    }
  }

  void _applySettingsBody(Map<String, dynamic> raw) {
    _paid = raw['paid'] == true;
    final prefs = raw['preferences'];
    if (prefs is Map) {
      for (final key in _prefs.keys.toList()) {
        _prefs[key] = prefs[key] != false;
      }
    }
    final notifications = raw['notifications'];
    _notices.clear();
    for (final entry in _groups) {
      final key = entry.$1;
      final row = notifications is Map ? notifications[key] : null;
      if (row is Map) {
        _notices[key] = {
          'inApp': row['inApp'] != false,
          'email': row['email'] != false,
          'push': row['push'] != false,
          'whatsapp': row['whatsapp'] != false,
          'locked': row['locked'] == true,
        };
      } else {
        _notices[key] = {
          ..._defaultChannels(),
          'locked': _lockedIds.contains(key) && _paid,
        };
      }
    }
    final opt = raw['whatsappOptIn'];
    if (opt is Map) {
      _whatsappRequested = opt['requested'] == true;
      _whatsappConfirmed = opt['confirmed'] == true;
    }
  }

  Future<void> _persist() async {
    final auth = widget.auth;
    if (auth == null) return;
    setState(() => _saving = true);
    try {
      final notifications = <String, dynamic>{
        for (final entry in _groups)
          entry.$1: {
            'inApp': _notices[entry.$1]?['inApp'] != false,
            'email': _notices[entry.$1]?['email'] != false,
            'push': _notices[entry.$1]?['push'] != false,
            'whatsapp': _notices[entry.$1]?['whatsapp'] != false,
          },
      };
      final timezone = _deviceTimezone();
      final raw = await auth.api.putSettings({
        'timezone': timezone,
        'preferences': {
          'immigration': true,
          ..._prefs,
        },
        'notifications': notifications,
      });
      if (!mounted) return;
      _applySettingsBody(raw);
      // Backend invalidateHomeLiveCache on timezone/prefs — refresh Home ribbon.
      widget.appState?.requestHomeRefresh();
      final savedTz = '${raw['timezone'] ?? ''}'.trim();
      // Auto-save fires often — only surface timezone problems, not every toggle.
      if (savedTz.isEmpty) {
        showProfileToast(
          context,
          'Preferences saved. Timezone could not be updated.',
        );
      }
    } on ApiException catch (error) {
      if (mounted) {
        showProfileToast(
          context,
          error.statusCode == 400
              ? error.message
              : 'Could not save notification settings.',
        );
      }
    } catch (_) {
      if (mounted) {
        showProfileToast(context, 'Could not save notification settings.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _setAndSave(VoidCallback apply) {
    setState(apply);
    _persist();
  }

  bool _groupLocked(String key) {
    final row = _notices[key];
    if (row?['locked'] == true) return true;
    return _paid && _lockedIds.contains(key);
  }

  Future<void> _startWhatsappOptIn() async {
    final auth = widget.auth;
    if (auth == null || _whatsappConfirmed) return;
    try {
      await auth.api.recordWhatsappOptIn(
        phone: auth.sessionUser?.phone ?? '',
      );
      if (mounted) setState(() => _whatsappRequested = true);
      final uri = Uri.parse(AppUrls.whatsapp);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      if (mounted) {
        showProfileToast(
          context,
          'Message FirstStep on WhatsApp to finish opt-in.',
        );
      }
    } catch (_) {
      if (mounted) {
        showProfileToast(context, 'Could not start WhatsApp opt-in.');
      }
    }
  }

  bool get _anyWhatsappOn =>
      _notices.values.any((row) => row['whatsapp'] != false);

  List<Widget> _sheetSections(BuildContext context) {
    final t = HomeTokens.of(context);
    if (_loading) {
      return const [
        Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    return [
      if (_loadError != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Text(_loadError!, style: TextStyle(color: t.mute, fontSize: 13)),
        ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
        child: Text(
          'Signed in as $_emailLabel. Immigration updates stay on. Quiet hours are 10 PM to 8 AM in your time zone.',
          style: TextStyle(fontSize: 12.5, height: 1.4, color: t.mute),
        ),
      ),
      _Group(
        title: 'Topics',
        children: [
          for (final pref in _prefLabels)
            _SwitchRow(
              icon: Icons.tune,
              title: pref.$2,
              subtitle: pref.$1 == 'aiNews'
                  ? 'Immigration stays on either way'
                  : '',
              value: _prefs[pref.$1] != false,
              onChanged: (v) => _setAndSave(() => _prefs[pref.$1] = v),
            ),
        ],
      ),
      _Group(
        title: 'WhatsApp',
        children: [
          _SwitchRow(
            icon: Icons.chat_bubble_outline,
            title: 'WhatsApp messages',
            subtitle: _whatsappConfirmed
                ? 'Opt-in confirmed'
                : _whatsappRequested
                    ? 'Tap again after messaging FirstStep'
                    : 'Interview and payment alerts',
            value: _anyWhatsappOn,
            onChanged: (enabled) {
              _setAndSave(() {
                for (final entry in _groups) {
                  if (_groupLocked(entry.$1)) continue;
                  _notices[entry.$1] = {
                    ...?_notices[entry.$1],
                    'whatsapp': enabled,
                  };
                }
              });
              if (enabled) _startWhatsappOptIn();
            },
          ),
        ],
      ),
      _Group(
        title: 'By topic',
        children: [
          for (final entry in _groups) ...[
            ListTile(
              dense: true,
              title: Text(
                '${entry.$2}${_groupLocked(entry.$1) ? ' · required' : ''}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: t.ink,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final channel in const [
                    ('inApp', 'In app'),
                    ('email', 'Email'),
                    ('push', 'Push'),
                    ('whatsapp', 'WhatsApp'),
                  ])
                    FilterChip(
                      label: Text(channel.$2),
                      selected: _notices[entry.$1]?[channel.$1] != false,
                      onSelected: _groupLocked(entry.$1)
                          ? null
                          : (selected) {
                              _setAndSave(() {
                                _notices[entry.$1] = {
                                  ...?_notices[entry.$1],
                                  channel.$1: selected,
                                };
                              });
                              if (channel.$1 == 'whatsapp' && selected) {
                                _startWhatsappOptIn();
                              }
                            },
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Text(
          _saving
              ? 'Saving…'
              : 'Applications and interviews arrive right away. Other pushes wait until quiet hours.',
          style: TextStyle(fontSize: 12.5, height: 1.45, color: t.mute),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return profileSheetShell(
      context: context,
      title: 'Notifications',
      children: _sheetSections(context),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return SwitchListTile(
      secondary: Icon(icon, color: t.ink, size: 20),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600, color: t.ink),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12.5, color: t.mute),
      ),
      value: value,
      activeThumbColor: t.teal,
      onChanged: onChanged,
    );
  }
}

Future<void> openSettings(
  BuildContext context,
  AppState appState, {
  AuthController? auth,
  ProfileStore? store,
}) {
  return showProfileBottomSheet<void>(
    context,
    heightFactor: 0.85,
    child: SettingsHelpPage(
      appState: appState,
      auth: auth,
      store: store,
    ),
  );
}

/// Same companies list as web DoNotApplyList — one company per line.
Future<void> openDoNotApplySheet(
  BuildContext context, {
  required AuthController auth,
  ProfileStore? store,
}) {
  return showProfileBottomSheet<void>(
    context,
    heightFactor: 0.75,
    child: _DoNotApplySheet(auth: auth, store: store),
  );
}

class _DoNotApplySheet extends StatefulWidget {
  const _DoNotApplySheet({required this.auth, this.store});

  final AuthController auth;
  final ProfileStore? store;

  @override
  State<_DoNotApplySheet> createState() => _DoNotApplySheetState();
}

class _DoNotApplySheetState extends State<_DoNotApplySheet> {
  late final TextEditingController _controller;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.store?.doNotApplyCompanies ?? const <String>[];
    _controller = TextEditingController(text: existing.join('\n'));
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final companies = await widget.auth.api.getDoNotApply();
      widget.store?.doNotApplyCompanies = companies;
      if (!mounted) return;
      _controller.text = companies.join('\n');
      setState(() => _loading = false);
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        showProfileToast(context, 'Could not load the do-not-apply list.');
      }
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final companies = _controller.text
        .split(RegExp(r'[\n,;]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    try {
      final saved = await widget.auth.api.putDoNotApply(companies);
      widget.store?.doNotApplyCompanies = saved;
      if (mounted) {
        showProfileToast(context, 'Do-not-apply list saved.');
        await closeProfileSheet(context);
      }
    } catch (_) {
      if (mounted) {
        showProfileToast(context, 'Could not save the list.');
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          profileSheetGrabber(t),
          const SizedBox(height: 8),
          Text(
            'Companies not to apply to',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: t.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'One company per line. Your application in charge sees a warning before applying. This does not block the application.',
            style: TextStyle(fontSize: 13, color: t.mute),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: TextStyle(color: t.ink, fontSize: 15),
                cursorColor: t.teal,
                decoration: profileFieldDecoration(t).copyWith(
                  hintText: 'Amazon\nOracle',
                ),
              ),
            ),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: t.navy,
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: _loading || _saving ? null : _save,
            child: Text(_saving ? 'Saving…' : 'Save list'),
          ),
        ],
      ),
    );
  }
}

class SettingsHelpPage extends StatefulWidget {
  final AppState appState;
  final AuthController? auth;
  final ProfileStore? store;

  const SettingsHelpPage({
    super.key,
    required this.appState,
    this.auth,
    this.store,
  });

  @override
  State<SettingsHelpPage> createState() => _SettingsHelpPageState();
}

class _SettingsHelpPageState extends State<SettingsHelpPage> {
  String get _appearanceLabel =>
      widget.appState.themeMode == ThemeMode.dark ? 'Dark' : 'Light';

  List<Widget> _sheetSections(BuildContext context) {
    final t = HomeTokens.of(context);
    return [
                _Group(
                  title: 'Settings',
                  children: [
                    _SetRow(
                      icon: Icons.notifications_none,
                      title: 'Notifications',
                      subtitle: 'Push, email, WhatsApp',
                      onTap: () => openNotifications(
                        context,
                        auth: widget.auth,
                        appState: widget.appState,
                      ),
                    ),
                    _SetRow(
                      icon: Icons.dark_mode_outlined,
                      title: 'Appearance',
                      subtitle: _appearanceLabel,
                      onTap: () async {
                        final next =
                            widget.appState.themeMode == ThemeMode.dark
                                ? ThemeMode.light
                                : ThemeMode.dark;
                        widget.appState.setThemeMode(next);
                        setState(() {});
                        final auth = widget.auth;
                        if (auth == null) return;
                        try {
                          await auth.api.patchTheme(
                            next == ThemeMode.dark ? 'dark' : 'light',
                          );
                        } catch (_) {
                          if (context.mounted) {
                            showProfileToast(
                              context,
                              'Theme saved on device only.',
                            );
                          }
                        }
                      },
                    ),
                    if (widget.auth != null)
                      _SetRow(
                        icon: Icons.badge_outlined,
                        title: 'Display name',
                        subtitle: widget.auth!.sessionUser?.displayName ??
                            'Change the name shown in Profile',
                        onTap: () => openDisplayNameSheet(
                          context,
                          auth: widget.auth!,
                          store: widget.store,
                        ),
                      ),
                    if (widget.auth != null)
                      _SetRow(
                        icon: Icons.block_outlined,
                        title: 'Do-not-apply list',
                        subtitle: 'Companies we should avoid',
                        onTap: () => openDoNotApplySheet(
                          context,
                          auth: widget.auth!,
                          store: widget.store,
                        ),
                      ),
                  ],
                ),
                _Group(
                  title: 'Help',
                  children: [
                    _SetRow(
                      icon: Icons.help_outline,
                      title: 'FAQ',
                      subtitle: 'Plans, applications, refunds',
                      onTap: () => openFaq(context),
                    ),
                    _SetRow(
                      icon: Icons.calendar_today_outlined,
                      title: 'Holiday calendar',
                      subtitle: 'FirstStep holidays & partner leave',
                      onTap: () => openHolidayCalendar(
                        context,
                        auth: widget.auth,
                      ),
                    ),
                    _SetRow(
                      icon: Icons.language,
                      title: 'Visit firststepjob.com',
                      subtitle: 'Opens the website',
                      onTap: () => openExternal(AppUrls.site),
                    ),
                    _SetRow(
                      icon: Icons.description_outlined,
                      title: 'Terms & privacy',
                      onTap: () => openTermsPrivacy(context),
                    ),
                  ],
                ),
                _Group(
                  title: 'Account',
                  children: [
                    _SetRow(
                      icon: Icons.logout,
                      title: 'Sign out',
                      onTap: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Sign out?'),
                            content: const Text(
                              'You can sign back in anytime with your email.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Sign out'),
                              ),
                            ],
                          ),
                        );
                        if (ok != true || !context.mounted) return;
                        // Close Settings sheet first so it doesn't linger over welcome.
                        Navigator.of(context).pop();
                        widget.appState.requestSignOut();
                      },
                    ),
                    _SetRow(
                      icon: Icons.delete_outline,
                      title: 'Delete account',
                      subtitle: 'Sends a request to our team',
                      danger: true,
                      onTap: () async {
                        final choice = await showDialog<String>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete account?'),
                            content: const Text(
                              'Nothing is deleted instantly. We email you and process the request. You can sign out after sending.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, 'cancel'),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, 'request'),
                                child: const Text('Request delete'),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, 'request_signout'),
                                child: const Text('Request & sign out'),
                              ),
                            ],
                          ),
                        );
                        if (choice == null ||
                            choice == 'cancel' ||
                            !context.mounted) {
                          return;
                        }
                        final auth = widget.auth;
                        if (auth == null) {
                          if (context.mounted) {
                            showProfileToast(
                              context,
                              'Sign in again to request account deletion.',
                            );
                          }
                          return;
                        }
                        var sent = false;
                        try {
                          await auth.api.deleteAccountRequest();
                          sent = true;
                          if (context.mounted) {
                            showProfileToast(
                              context,
                              'Delete request sent. We emailed you. Nothing is deleted instantly.',
                            );
                          }
                        } catch (_) {
                          if (context.mounted) {
                            showProfileToast(
                              context,
                              'Could not send request. Try again.',
                            );
                          }
                        }
                        if (!context.mounted || !sent) return;
                        Navigator.of(context).pop();
                        if (choice == 'request_signout') {
                          widget.appState.requestSignOut();
                        }
                      },
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: Center(
                    child: Text(
                      'FirstStep 1.0.0',
                      style: TextStyle(fontSize: 12.5, color: t.mute),
                    ),
                  ),
                ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        return profileSheetShell(
          context: context,
          title: 'Settings & help',
          children: _sheetSections(context),
        );
      },
    );
  }
}


class _Group extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Group({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: t.mute,
              ),
            ),
          ),
          Material(
            color: t.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: t.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool danger;

  const _SetRow({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final color = danger ? t.alert : t.ink;
    return ListTile(
      leading: Icon(icon, color: color, size: 20),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600, color: color),
      ),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, style: TextStyle(fontSize: 12.5, color: t.mute)),
      trailing: danger ? null : Icon(Icons.chevron_right, color: t.mute),
      onTap: onTap,
    );
  }
}
