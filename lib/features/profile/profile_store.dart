import 'package:flutter/foundation.dart';

import '../../api/bootstrap_models.dart';
import '../../api/profile_models.dart';

enum ProfilePlan { premium, premiumPlus, elite, basic }

class PlanBenefitChip {
  final String title;
  final String status; // e.g. "1 of 2", "18 Nov"
  final String pastel; // lav | pch | sky | but
  final String formKey; // mock | linkedin | portfolio | scoutx
  final String? formUrl;

  const PlanBenefitChip({
    required this.title,
    required this.status,
    required this.pastel,
    required this.formKey,
    this.formUrl,
  });
}

class ProfileDoc {
  final String title;
  final String subtitle;
  final String id;
  final String fileName;
  final bool canDownload;

  const ProfileDoc(
    this.title,
    this.subtitle, {
    this.id = '',
    this.fileName = '',
    this.canDownload = false,
  });
}

class ProfileTicket {
  final String reason;
  final String number;
  final String preview;
  final String when;
  final String status; // Open | Replied | Resolved

  const ProfileTicket({
    required this.reason,
    required this.number,
    required this.preview,
    required this.when,
    required this.status,
  });
}

class ProfileContent {
  final String name;
  final String initial;
  final String subtitle;
  final ProfilePlan plan;
  final bool whatsapp;
  final String memberSince;
  final String midStat;
  final String midLabel;
  final String badgeStat;
  final String badgeLabel;
  final String rewards;
  final int badges;
  final String planName;
  final String planDates;
  final String planUseBy;
  final double progress;
  final String daysLeft;
  final bool portfolioReady;
  final List<String> roles;
  final String email;
  final bool showIntake;

  const ProfileContent({
    required this.name,
    required this.initial,
    required this.subtitle,
    required this.plan,
    required this.whatsapp,
    required this.memberSince,
    required this.midStat,
    required this.midLabel,
    required this.badgeStat,
    required this.badgeLabel,
    required this.rewards,
    required this.badges,
    required this.planName,
    required this.planDates,
    required this.planUseBy,
    required this.progress,
    required this.daysLeft,
    this.portfolioReady = false,
    required this.roles,
    required this.email,
    required this.showIntake,
  });

  bool get isBasic => plan == ProfilePlan.basic;

  bool get showBenefitChips =>
      plan == ProfilePlan.premium || plan == ProfilePlan.premiumPlus;

  bool get showBenefitsUpsell => plan == ProfilePlan.elite;

  ProfileContent copyWith({
    String? name,
    String? initial,
    String? subtitle,
    ProfilePlan? plan,
    bool? whatsapp,
    String? memberSince,
    String? midStat,
    String? midLabel,
    String? badgeStat,
    String? badgeLabel,
    String? rewards,
    int? badges,
    String? planName,
    String? planDates,
    String? planUseBy,
    double? progress,
    String? daysLeft,
    bool? portfolioReady,
    List<String>? roles,
    String? email,
    bool? showIntake,
  }) {
    return ProfileContent(
      name: name ?? this.name,
      initial: initial ?? this.initial,
      subtitle: subtitle ?? this.subtitle,
      plan: plan ?? this.plan,
      whatsapp: whatsapp ?? this.whatsapp,
      memberSince: memberSince ?? this.memberSince,
      midStat: midStat ?? this.midStat,
      midLabel: midLabel ?? this.midLabel,
      badgeStat: badgeStat ?? this.badgeStat,
      badgeLabel: badgeLabel ?? this.badgeLabel,
      rewards: rewards ?? this.rewards,
      badges: badges ?? this.badges,
      planName: planName ?? this.planName,
      planDates: planDates ?? this.planDates,
      planUseBy: planUseBy ?? this.planUseBy,
      progress: progress ?? this.progress,
      daysLeft: daysLeft ?? this.daysLeft,
      portfolioReady: portfolioReady ?? this.portfolioReady,
      roles: roles ?? this.roles,
      email: email ?? this.email,
      showIntake: showIntake ?? this.showIntake,
    );
  }
}

class ProfileStore extends ChangeNotifier {
  ProfilePlan plan;
  ProfileContent content;

  /// Avatar: init | dots | stripes | rings | waves, pastel key.
  String avatarKind = 'init';
  String avatarBg = 'lav';
  /// Bootstrap / Auth0 picture URL (same field web ProfileHub uses).
  String pictureUrl = '';
  /// When true, keep a chosen pattern and do not refill pictureUrl from session.
  bool preferLocalAvatar = false;

  String location;
  String tech;
  String rolesOfInterest;
  String workAuthorization;
  String experience;
  String news = 'Immigration (always on) · AI · Industry';
  String learningTime;

  bool loading = false;
  bool hasRemote = false;
  String? loadError;

  List<ProfileDoc> docs = const [];
  List<ProfileTicket> tickets = const [];
  int supportOpenCount = 0;
  PlanDetailsInfo? planDetails;
  PlanBenefitsSummary? remoteBenefits;
  String whatsappGroupUrl = '';
  String referralCode = '';
  double rewardsBalanceUsd = 0;
  bool paymentDue = false;
  bool showRenew = false;
  String planStatus = '';
  List<String> doNotApplyCompanies = const [];

  ProfileStore({this.plan = ProfilePlan.basic})
      : content = _emptyContent,
        location = 'Add your city',
        tech = 'Not set',
        rolesOfInterest = 'Add up to 3 roles',
        workAuthorization = '',
        experience = '',
        learningTime = 'Not set';

  /// Apply bootstrap identity immediately so the header is never blank.
  void applySessionUser(SessionUser? user) {
    if (user == null) return;
    final name = user.displayName;
    if (user.referralCode.isNotEmpty) {
      referralCode = user.referralCode;
    }
    if (!preferLocalAvatar && user.picture.isNotEmpty) {
      pictureUrl = user.picture;
    }
    content = content.copyWith(
      name: name,
      initial: user.initial,
      email: user.email,
      subtitle: content.planName.isEmpty
          ? name
          : '${content.roles.isNotEmpty ? content.roles.first : name} · ${content.planName}',
    );
    notifyListeners();
  }

  /// Merge plan / rewards / badges / intake from existing /api/me GETs.
  void applyRemote({
    SessionUser? user,
    PlanSummary? planSummary,
    RewardsSummary? rewards,
    List<BadgeItem>? badges,
    IntakeProfileSummary? intake,
    DocumentsSummary? documents,
    SupportTicketsSummary? ticketsSummary,
    PlanBenefitsSummary? planBenefits,
    AppProfileSummary? appProfile,
    PlanDetailsInfo? planDetailsInfo,
    String? error,
  }) {
    loadError = error;
    final session = user;
    final name = session?.displayName ?? content.name;
    final email = session?.email ?? content.email;
    final initial = session?.initial ?? content.initial;
    if (!preferLocalAvatar && session?.picture.isNotEmpty == true) {
      pictureUrl = session!.picture;
    }

    final planName = (planSummary?.plan.trim().isNotEmpty ?? false)
        ? planSummary!.plan.trim()
        : content.planName;
    final mapped = mapPlanType(planName);
    plan = mapped;
    avatarBg = switch (mapped) {
      ProfilePlan.elite => 'mint',
      ProfilePlan.basic => 'sky',
      ProfilePlan.premiumPlus => 'pch',
      ProfilePlan.premium => 'lav',
    };

    final roles = planSummary?.categories ?? content.roles;
    final earnedBadges =
        badges?.where((item) => item.earned).length ?? content.badges;
    final rewardLabel = rewards?.balanceLabel ?? content.rewards;
    if (rewards != null) {
      rewardsBalanceUsd = rewards.balanceUsd;
    }
    if (rewards?.referralCode.isNotEmpty == true) {
      referralCode = rewards!.referralCode;
    } else if (session?.referralCode.isNotEmpty == true) {
      referralCode = session!.referralCode;
    }

    String planDates = content.planDates;
    String daysLeft = content.daysLeft;
    String planUseBy = content.planUseBy;
    double progress = content.progress;
    if (planSummary != null) {
      paymentDue = planSummary.paymentDue;
      showRenew = planSummary.showRenew;
      planStatus = planSummary.status;
      if (planSummary.paymentDue) {
        planDates = 'Payment due';
        daysLeft = 'Payment due';
      } else if (planSummary.showRenew) {
        planDates = planSummary.discount
            ? 'Renewal offer · \$30 off'
            : 'Renewal available';
        daysLeft = 'Renew soon';
      } else if (mapped == ProfilePlan.basic) {
        planDates = '';
        daysLeft = '';
        planUseBy = '';
        progress = 0;
      } else {
        if (planSummary.startDate.isNotEmpty && planSummary.endDate.isNotEmpty) {
          planDates = '${planSummary.startDate} – ${planSummary.endDate}';
        } else if (planSummary.endDate.isNotEmpty) {
          planDates = 'Through ${planSummary.endDate}';
        }
        if (planSummary.daysLeft > 0) {
          daysLeft = '${planSummary.daysLeft} days left';
        } else if (planSummary.endDate.isNotEmpty) {
          daysLeft = 'Ends ${planSummary.endDate}';
        }
        if (planSummary.endDate.isNotEmpty) {
          planUseBy = planSummary.endDate;
        }
        var p = planSummary.progress;
        if (p > 1) p = p / 100;
        if (p > 0) progress = p.clamp(0.0, 1.0);
      }
    }

    final memberSince =
        session?.memberSinceLabel.isNotEmpty == true &&
                session!.memberSinceLabel != '—'
            ? session.memberSinceLabel
            : content.memberSince;

    var midStat = content.midStat;
    var midLabel = content.midLabel;
    if (documents != null) {
      midStat = '${documents.uploadedCount}';
      midLabel = documents.uploadedCount == 1 ? 'document' : 'documents';
      docs = documents.items
          .map(
            (d) => ProfileDoc(
              d.title,
              d.subtitle,
              id: d.id,
              fileName: d.fileName,
              canDownload: d.canDownload,
            ),
          )
          .toList();
    }

    if (ticketsSummary != null) {
      supportOpenCount = ticketsSummary.openCount;
      tickets = ticketsSummary.items.map(_mapTicket).toList();
    }

    if (planBenefits != null) {
      remoteBenefits = planBenefits;
      if (planBenefits.useBy.isNotEmpty) {
        planUseBy = planBenefits.useBy;
      }
      if (planBenefits.whatsappGroupUrl.isNotEmpty) {
        whatsappGroupUrl = planBenefits.whatsappGroupUrl;
      }
    }
    if (session?.whatsappGroupUrl.isNotEmpty == true) {
      whatsappGroupUrl = session!.whatsappGroupUrl;
    }

    if (planDetailsInfo != null) {
      planDetails = planDetailsInfo;
    }

    final whatsappUrl = whatsappGroupUrl.trim();
    final whatsapp = whatsappUrl.isNotEmpty ||
        mapped == ProfilePlan.premium ||
        mapped == ProfilePlan.premiumPlus;

    if (appProfile != null) {
      _mergeAppProfile(appProfile);
    }

    final roleHint =
        roles.isNotEmpty ? roles.first : (mapped == ProfilePlan.basic ? '' : name);
    final subtitle = mapped == ProfilePlan.basic
        ? (planName.isEmpty ? 'Basic' : planName)
        : [
            if (roleHint.isNotEmpty) roleHint,
            if (planName.isNotEmpty) planName,
          ].join(' · ');

    if (intake != null) {
      if (intake.location.trim().isNotEmpty) {
        location = intake.location.trim();
      } else if (location.isEmpty || location.startsWith('Add')) {
        location = 'Add your city';
      }
      if (intake.tech.trim().isNotEmpty) {
        tech = intake.tech.trim();
      } else if (tech.isEmpty) {
        tech = 'Not set';
      }
      if (intake.rolesOfInterest.trim().isNotEmpty) {
        rolesOfInterest = intake.rolesOfInterest.trim();
      } else if (roles.isNotEmpty) {
        rolesOfInterest = roles.join(', ');
      } else if (rolesOfInterest.isEmpty || rolesOfInterest.startsWith('Add')) {
        rolesOfInterest = 'Add up to 3 roles';
      }
      if (intake.workAuthorization.trim().isNotEmpty) {
        workAuthorization = intake.workAuthorization.trim();
      }
      if (intake.experience.trim().isNotEmpty) {
        experience = intake.experience.trim();
      }
      learningTime =
          learningTime.isEmpty ? 'Not set' : learningTime;
    } else if (roles.isNotEmpty) {
      rolesOfInterest = roles.join(', ');
    }

    content = ProfileContent(
      name: name.isEmpty ? 'Your profile' : name,
      initial: initial.isEmpty ? '?' : initial,
      subtitle: subtitle.isEmpty ? name : subtitle,
      plan: mapped,
      whatsapp: whatsapp,
      memberSince: memberSince,
      midStat: midStat,
      midLabel: midLabel,
      badgeStat: '$earnedBadges',
      badgeLabel: earnedBadges == 1 ? 'badge' : 'badges',
      rewards: rewardLabel,
      badges: earnedBadges,
      planName: planName.isEmpty ? 'Basic' : planName,
      planDates: planDates,
      planUseBy: planUseBy,
      progress: progress,
      daysLeft: daysLeft,
      portfolioReady: content.portfolioReady,
      roles: roles,
      email: email,
      showIntake: mapped != ProfilePlan.basic,
    );
    notifyListeners();
    hasRemote = true;
  }

  void setLoading(bool value) {
    loading = value;
    notifyListeners();
  }

  /// Maps server subscription_type onto UI branches used by benefit chips.
  static ProfilePlan mapPlanType(String raw) {
    final key = raw.toLowerCase().replaceAll(RegExp(r'[\s_\-]+'), '');
    if (key.contains('premiumplus') || key == 'premium+') {
      return ProfilePlan.premiumPlus;
    }
    if (key.contains('premium') || key.contains('falconlite') || key == 'falcon') {
      return ProfilePlan.premium;
    }
    if (key.contains('elite') || key.contains('essentials')) {
      return ProfilePlan.elite;
    }
    return ProfilePlan.basic;
  }

  static const _emptyContent = ProfileContent(
    name: 'Your profile',
    initial: '?',
    subtitle: '',
    plan: ProfilePlan.basic,
    whatsapp: false,
    memberSince: '—',
    midStat: '0',
    midLabel: 'documents',
    badgeStat: '0',
    badgeLabel: 'badges',
    rewards: '\$0',
    badges: 0,
    planName: '',
    planDates: '',
    planUseBy: '',
    progress: 0,
    daysLeft: '',
    roles: [],
    email: '',
    showIntake: false,
  );

  void setAvatar(String kind, String bg) {
    avatarKind = kind;
    avatarBg = bg;
    // Prefer the chosen pattern over the network photo while this session lasts.
    preferLocalAvatar = true;
    pictureUrl = '';
    notifyListeners();
  }

  void removePhoto() {
    avatarKind = 'init';
    preferLocalAvatar = true;
    pictureUrl = '';
    notifyListeners();
  }

  void updatePref(String key, String value) {
    switch (key) {
      case 'Location':
        location = value;
      case 'Tech stack':
        tech = value;
      case 'Roles of interest':
        rolesOfInterest = value;
      case 'News topics':
        news = value;
      case 'Daily learning time':
        learningTime = value;
    }
    notifyListeners();
  }

  String prefValue(String key) {
    switch (key) {
      case 'Location':
        return location;
      case 'Tech stack':
        return tech;
      case 'Roles of interest':
        return rolesOfInterest;
      case 'News topics':
        return news;
      case 'Daily learning time':
        return learningTime;
      default:
        return '';
    }
  }

  void _mergeAppProfile(AppProfileSummary appProfile) {
    if (appProfile.location.isNotEmpty) location = appProfile.location;
    if (appProfile.tech.isNotEmpty) tech = appProfile.tech;
    if (appProfile.rolesOfInterest.isNotEmpty) {
      rolesOfInterest = appProfile.rolesOfInterest;
    }
    if (appProfile.newsTopics.isNotEmpty) news = appProfile.newsTopics;
    if (appProfile.learningTime.isNotEmpty) {
      learningTime = appProfile.learningTime;
    }
    if (appProfile.workAuthorization.isNotEmpty) {
      workAuthorization = appProfile.workAuthorization;
    }
    if (appProfile.experience.isNotEmpty) {
      experience = appProfile.experience;
    }
  }

  static ProfileTicket _mapTicket(SupportTicketItem item) {
    final status = _displayTicketStatus(item.status);
    final id = item.id;
    final number = id.length > 6 ? '#${id.substring(id.length - 4)}' : '#$id';
    final preview = item.description.length > 48
        ? '${item.description.substring(0, 45)}…'
        : item.description;
    return ProfileTicket(
      reason: item.type.isEmpty ? 'Support' : item.type,
      number: number,
      preview: preview,
      when: _formatTicketWhen(item.createdAt),
      status: status,
    );
  }

  static String _displayTicketStatus(String raw) {
    final key = raw.toLowerCase().replaceAll(' ', '_');
    if (key == 'new' ||
        key == 'in_progress' ||
        key == 'waiting_for_user' ||
        key == 'open') {
      return 'Open';
    }
    if (key.contains('reply') || key == 'waiting_for_user') return 'Replied';
    if (key == 'resolved' || key == 'closed' || key == 'done') {
      return 'Resolved';
    }
    if (raw.isEmpty) return 'Open';
    return raw[0].toUpperCase() + raw.substring(1);
  }

  static String _formatTicketWhen(String createdAt) {
    if (createdAt.isEmpty) return '—';
    final dt = DateTime.tryParse(createdAt);
    if (dt == null) return '—';
    final now = DateTime.now();
    final local = dt.toLocal();
    if (local.year == now.year &&
        local.month == now.month &&
        local.day == now.day) {
      return 'Today';
    }
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
    return '${local.day} ${months[local.month - 1]}';
  }

  static const _chipPastels = ['lav', 'pch', 'sky', 'but'];

  List<PlanBenefitChip> get planBenefits {
    final c = content;
    if (!c.showBenefitChips) return const [];
    final remote = remoteBenefits;
    if (remote != null && remote.chips.isNotEmpty) {
      return [
        for (var i = 0; i < remote.chips.length; i++)
          if (remote.chips[i].included)
            PlanBenefitChip(
              title: remote.chips[i].title,
              status: remote.chips[i].status,
              pastel: _chipPastels[i % _chipPastels.length],
              formKey: remote.chips[i].key,
              formUrl: remote.chips[i].formUrl.isEmpty
                  ? null
                  : remote.chips[i].formUrl,
            ),
      ];
    }
    final chips = <PlanBenefitChip>[
      const PlanBenefitChip(
        title: 'Mock interview',
        status: '1 of 2',
        pastel: 'lav',
        formKey: 'mock',
      ),
      PlanBenefitChip(
        title: 'LinkedIn',
        status: c.plan == ProfilePlan.premiumPlus ? '18 Nov' : '18 Nov',
        pastel: 'pch',
        formKey: 'linkedin',
      ),
    ];
    if (c.plan == ProfilePlan.premiumPlus) {
      chips.add(
        PlanBenefitChip(
          title: 'Portfolio',
          status: c.portfolioReady ? 'Ready' : 'In progress',
          pastel: 'sky',
          formKey: 'portfolio',
        ),
      );
      chips.add(
        const PlanBenefitChip(
          title: 'ScoutX',
          status: '2',
          pastel: 'but',
          formKey: 'scoutx',
        ),
      );
    }
    return chips;
  }

  int get personalFilled {
    var n = 0;
    if (!location.startsWith('Add')) n++;
    if (tech.isNotEmpty && tech != 'Not set') n++;
    if (!rolesOfInterest.startsWith('Add')) n++;
    if (news.isNotEmpty) n++;
    if (learningTime != 'Not set') n++;
    return n;
  }

  /// pastel key · title · subtitle (icons live in the ticket sheet)
  static const reasons = [
    ('lav', 'Change my details', 'Contact, education, experience'),
    ('pch', 'Change my target roles', 'Your plan allows a set number'),
    ('but', 'Add a company to avoid', "We won't apply there"),
    ('sky', 'Plan & billing', 'Dates, invoices, upgrades'),
    ('mint', 'Application question', 'About a job we applied to'),
    ('', 'Something else', 'Anything we can help with'),
  ];

  static const avatars = [
    ('init', 'lav'),
    ('init', 'sky'),
    ('init', 'mint'),
    ('init', 'pch'),
    ('dots', 'lav'),
    ('stripes', 'but'),
    ('rings', 'sky'),
    ('waves', 'mint'),
  ];
}
