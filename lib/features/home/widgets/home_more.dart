part of '../focus_home_view.dart';

class _DiscoverCards extends StatelessWidget {
  final List<NewsCard> cards;
  final ApiClient? api;

  const _DiscoverCards({required this.cards, this.api});

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final items = cards;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Discover',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: t.ink,
              ),
            ),
            GestureDetector(
              onTap: () => openNewsFeed(context, api: api),
              child: Text(
                'See all',
                style: TextStyle(
                  fontSize: 13,
                  color: t.teal,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final card = items[i];
              final pastel = switch (card.pastel) {
                'sky' => t.sky,
                'lavender' => t.lavender,
                'mint' => t.mint,
                'peach' => t.peach,
                _ => t.butter,
              };
              return Material(
                color: t.card,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => openNewsFeed(context, api: api, focus: card),
                  child: Container(
                    width: 232,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: t.line),
                      boxShadow: t.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TypeChip(
                          label: card.category,
                          fg: pastel.fg,
                          bg: pastel.bg,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          card.title,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: t.ink,
                            height: 1.35,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Text(
                          card.readTime,
                          style: TextStyle(fontSize: 12, color: t.mute),
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

class _ProofStats extends StatelessWidget {
  final ProofStats stats;

  const _ProofStats({required this.stats});

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final tones = [t.sky, t.lavender, t.mint];
    return Row(
      children: [
        for (var i = 0; i < stats.values.length; i++)
          Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i == stats.values.length - 1 ? 0 : 8),
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
              decoration: BoxDecoration(
                color: tones[i % tones.length].bg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stats.values[i],
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.4,
                      color: t.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stats.captions[i],
                    style: TextStyle(
                      fontSize: 11.5,
                      color: t.ink.withValues(alpha: 0.72),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _SellCard extends StatelessWidget {
  final SellCard sell;
  final AppState? appState;

  const _SellCard({required this.sell, this.appState});

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.line),
        boxShadow: t.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Let our team apply for you',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: t.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'A real person sends 25–45 applications for you every weekday, while you prepare for interviews.',
            style: TextStyle(fontSize: 13.5, color: t.mute, height: 1.5),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < sell.miniChips.length; i++)
                _TypeChip(
                  label: sell.miniChips[i],
                  fg: [t.mint, t.sky, t.lavender, t.butter][i % 4].fg,
                  bg: [t.mint, t.sky, t.lavender, t.butter][i % 4].bg,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < sell.actions.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _PillButton(
                    label: sell.actions[i],
                    bg: i == 0 ? t.ctaBg : Colors.transparent,
                    ink: i == 0 ? t.ctaInk : t.ctaBg,
                    outline: i > 0,
                    appState: appState,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => openExternal(AppUrls.whatsapp),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_rounded, size: 16, color: t.teal),
                const SizedBox(width: 6),
                Text(
                  'Questions? Chat on WhatsApp',
                  style: TextStyle(
                    fontSize: 13,
                    color: t.teal,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NewJobs extends StatelessWidget {
  final List<JobTeaser> jobs;
  final AppState? appState;

  const _NewJobs({required this.jobs, this.appState});

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return Container(
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.line),
        boxShadow: t.cardShadow,
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => appState?.setMainTabIndex(1),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '8 new Data Engineer jobs today',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: t.ink,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: t.mute),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                _FilterChip(label: 'Remote'),
                const SizedBox(width: 6),
                _FilterChip(label: 'Last 24 h', locked: true),
                const SizedBox(width: 6),
                _FilterChip(label: 'H-1B sponsor', locked: true),
              ],
            ),
          ),
          for (final job in jobs)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => appState?.setMainTabIndex(1),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: t.line)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color:
                              job.pastel == 'sky' ? t.sky.bg : t.lavender.bg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          job.letter,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: job.pastel == 'sky'
                                ? t.sky.fg
                                : t.lavender.fg,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: t.ink,
                              ),
                            ),
                            Text(
                              job.meta,
                              style:
                                  TextStyle(fontSize: 12.5, color: t.mute),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool locked;

  const _FilterChip({required this.label, this.locked = false});

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: t.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (locked) ...[
            Icon(Icons.lock_outline_rounded, size: 11, color: t.mute),
            const SizedBox(width: 4),
          ],
          Text(label, style: TextStyle(fontSize: 12, color: t.mute)),
        ],
      ),
    );
  }
}

class _ReferRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final b = t.butter;
    return Column(
      children: [
        Material(
          color: b.bg,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => shareText(
              context,
              'Join FirstStep with my link',
              AppUrls.referralFor(null),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: t.card,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.card_giftcard_outlined,
                      size: 20,
                      color: b.fg,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Refer a friend, get \$15',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: t.ink,
                          ),
                        ),
                        Text(
                          'Use it on add-ons like resume prep.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: t.ink.withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: t.mute),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        GestureDetector(
          onTap: () => openExternal(AppUrls.site),
          child: Text(
            'Paid with a different email?',
            style: TextStyle(
              fontSize: 13,
              color: t.mute,
              decoration: TextDecoration.underline,
              decorationColor: t.mute,
            ),
          ),
        ),
      ],
    );
  }
}

class _StateBanner extends StatelessWidget {
  final StateBanner banner;
  final AppState? appState;

  const _StateBanner({required this.banner, this.appState});

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final isAlumni = banner.kind == 'alumni';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAlumni ? null : t.butter.bg,
        gradient: isAlumni
            ? const LinearGradient(
                colors: [Color(0xFF06334A), Color(0xFF2F8090)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            banner.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isAlumni ? Colors.white : t.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            banner.body,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: isAlumni
                  ? Colors.white.withValues(alpha: 0.85)
                  : t.ink.withValues(alpha: 0.85),
            ),
          ),
          if (banner.actions.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                for (var i = 0; i < banner.actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _PillButton(
                      label: banner.actions[i],
                      bg: i == 0
                          ? (isAlumni ? Colors.white : t.ctaBg)
                          : Colors.transparent,
                      ink: i == 0
                          ? (isAlumni ? const Color(0xFF06334A) : t.ctaInk)
                          : (isAlumni ? Colors.white : t.ink),
                      outline: i > 0,
                      appState: appState,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

