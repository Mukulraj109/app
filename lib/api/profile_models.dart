/// Shapes from existing /api/me profile GETs (same fields as web ProfileHub).

class PlanSummary {
  const PlanSummary({
    required this.plan,
    this.categories = const [],
    this.paymentDue = false,
    this.showRenew = false,
    this.discount = false,
    this.status = '',
    this.startDate = '',
    this.endDate = '',
    this.daysLeft = 0,
    this.daysTotal = 0,
    this.progress = 0,
  });

  final String plan;
  final List<String> categories;
  final bool paymentDue;
  final bool showRenew;
  final bool discount;
  final String status;
  final String startDate;
  final String endDate;
  final int daysLeft;
  final int daysTotal;
  final double progress;

  factory PlanSummary.fromJson(Map<String, dynamic> json) {
    final rawCats = json['categories'];
    final categories = <String>[];
    if (rawCats is List) {
      for (final item in rawCats) {
        final text = '$item'.trim();
        if (text.isNotEmpty) categories.add(text);
      }
    }
    return PlanSummary(
      plan: _planLabel(json['plan']),
      categories: categories,
      paymentDue: json['paymentDue'] == true,
      showRenew: json['showRenew'] == true,
      discount: json['discount'] == true,
      status: '${json['status'] ?? ''}'.trim(),
      startDate: '${json['startDate'] ?? ''}'.trim(),
      endDate: '${json['endDate'] ?? ''}'.trim(),
      daysLeft: _asInt(json['daysLeft']),
      daysTotal: _asInt(json['daysTotal']),
      progress: _asDouble(json['progress']),
    );
  }

  static String _planLabel(Object? raw) {
    if (raw == null) return 'Normal Plan';
    final text = '$raw'.trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return 'Normal Plan';
    return text;
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  static double _asDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }
}

class RewardsSummary {
  const RewardsSummary({
    this.balanceUsd = 0,
    this.referralCode = '',
  });

  final double balanceUsd;
  final String referralCode;

  factory RewardsSummary.fromJson(Map<String, dynamic> json) {
    return RewardsSummary(
      balanceUsd: _asDouble(json['balanceUsd']),
      referralCode: '${json['referralCode'] ?? ''}'.trim(),
    );
  }

  String get balanceLabel {
    final whole = balanceUsd == balanceUsd.roundToDouble();
    final text = whole
        ? balanceUsd.toStringAsFixed(0)
        : balanceUsd.toStringAsFixed(2);
    return '\$$text';
  }

  static double _asDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }
}

class BadgeItem {
  const BadgeItem({
    required this.key,
    required this.title,
    required this.earned,
  });

  final String key;
  final String title;
  final bool earned;

  factory BadgeItem.fromJson(Map<String, dynamic> json) {
    return BadgeItem(
      key: '${json['key'] ?? ''}'.trim(),
      title: '${json['title'] ?? ''}'.trim(),
      earned: json['earned'] == true,
    );
  }
}

class IntakeProfileSummary {
  const IntakeProfileSummary({
    this.submitted = false,
    this.location = '',
    this.tech = '',
    this.rolesOfInterest = '',
    this.workAuthorization = '',
    this.experience = '',
  });

  final bool submitted;
  final String location;
  final String tech;
  final String rolesOfInterest;
  final String workAuthorization;
  final String experience;

  factory IntakeProfileSummary.fromJson(Map<String, dynamic> json) {
    final rawGroups = json['groups'];
    Map<String, dynamic> groups = const {};
    if (rawGroups is Map<String, dynamic>) {
      groups = rawGroups;
    } else if (rawGroups is Map) {
      groups = Map<String, dynamic>.from(rawGroups);
    }
    return IntakeProfileSummary(
      submitted: json['submitted'] == true,
      location: _firstString(groups, const [
        'location',
        'city',
        'currentLocation',
        'current_location',
        'homeCity',
        'preferredLocations',
        'preferred_locations',
      ]),
      tech: _firstString(groups, const [
        'tech',
        'techStack',
        'tech_stack',
        'skills',
        'stack',
      ]),
      rolesOfInterest: _rolesFrom(groups),
      workAuthorization: _firstString(groups, const [
        'workAuthorization',
        'work_authorization',
        'workAuth',
        'work_auth',
        'visaStatus',
        'visa_status',
      ]),
      experience: _firstString(groups, const [
        'experienceYears',
        'experience_years',
        'experience',
        'yearsOfExperience',
        'years_of_experience',
      ]),
    );
  }

  static String _rolesFrom(Map<String, dynamic> groups) {
    final direct = _firstString(groups, const [
      'roles',
      'rolesOfInterest',
      'roles_of_interest',
      'targetRoles',
      'target_roles',
      'categories',
    ]);
    if (direct.isNotEmpty) return direct;
    return '';
  }

  static String _firstString(
    Map<String, dynamic> groups,
    List<String> keys,
  ) {
    for (final key in keys) {
      final hit = _asDisplayString(groups[key]);
      if (hit.isNotEmpty) return hit;
      for (final value in groups.values) {
        if (value is Map) {
          final nested = Map<String, dynamic>.from(value);
          final nestedHit = _asDisplayString(nested[key]);
          if (nestedHit.isNotEmpty) return nestedHit;
        }
      }
    }
    return '';
  }

  static String _asDisplayString(Object? value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    if (value is num || value is bool) return '$value'.trim();
    if (value is List) {
      return value
          .map((item) => '$item'.trim())
          .where((item) => item.isNotEmpty)
          .join(', ');
    }
    return '';
  }
}

class PlanDetailsInfo {
  const PlanDetailsInfo({
    required this.plan,
    this.description = '',
    this.features = const [],
  });

  final String plan;
  final String description;
  final List<String> features;

  factory PlanDetailsInfo.fromJson(Map<String, dynamic> json) {
    final raw = json['features'];
    final features = <String>[];
    if (raw is List) {
      for (final item in raw) {
        final text = '$item'.trim();
        if (text.isNotEmpty) features.add(text);
      }
    }
    return PlanDetailsInfo(
      plan: '${json['plan'] ?? ''}'.trim(),
      description: '${json['description'] ?? ''}'.trim(),
      features: features,
    );
  }
}

class ProfileDocumentItem {
  const ProfileDocumentItem({
    required this.title,
    this.id = '',
    this.fileName = '',
    this.isUploaded = false,
    this.canDownload = false,
    this.uploadedAt = '',
  });

  final String id;
  final String title;
  final String fileName;
  final bool isUploaded;
  final bool canDownload;
  final String uploadedAt;

  factory ProfileDocumentItem.fromJson(Map<String, dynamic> json) {
    final uploaded = json['isUploaded'] == true;
    final id = '${json['id'] ?? ''}'.trim();
    return ProfileDocumentItem(
      id: id,
      title: '${json['title'] ?? ''}'.trim(),
      fileName: '${json['fileName'] ?? ''}'.trim(),
      isUploaded: uploaded,
      canDownload: json['canDownload'] == true || (uploaded && id.isNotEmpty),
      uploadedAt: '${json['uploadedAt'] ?? ''}'.trim(),
    );
  }

  String get subtitle {
    if (!isUploaded) return 'Not uploaded';
    if (uploadedAt.isEmpty) return 'Uploaded';
    final dt = DateTime.tryParse(uploadedAt);
    if (dt == null) return 'Uploaded';
    return 'Uploaded ${dt.day} ${_month(dt.month)}';
  }

  static String _month(int m) {
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
    return months[m - 1];
  }
}

class DocumentsSummary {
  const DocumentsSummary({
    this.uploadedCount = 0,
    this.items = const [],
  });

  final int uploadedCount;
  final List<ProfileDocumentItem> items;

  factory DocumentsSummary.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    final items = <ProfileDocumentItem>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          items.add(
            ProfileDocumentItem.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    final count = json['uploadedCount'];
    return DocumentsSummary(
      uploadedCount: count is int
          ? count
          : (count is num
              ? count.toInt()
              : items.where((d) => d.isUploaded).length),
      items: items,
    );
  }
}

class SupportTicketItem {
  const SupportTicketItem({
    required this.id,
    required this.type,
    required this.description,
    required this.status,
    this.createdAt = '',
  });

  final String id;
  final String type;
  final String description;
  final String status;
  final String createdAt;

  factory SupportTicketItem.fromJson(Map<String, dynamic> json) {
    return SupportTicketItem(
      id: '${json['id'] ?? ''}'.trim(),
      type: '${json['type'] ?? ''}'.trim(),
      description: '${json['description'] ?? ''}'.trim(),
      status: '${json['status'] ?? ''}'.trim(),
      createdAt: '${json['createdAt'] ?? ''}'.trim(),
    );
  }
}

class SupportTicketsSummary {
  const SupportTicketsSummary({
    this.openCount = 0,
    this.items = const [],
  });

  final int openCount;
  final List<SupportTicketItem> items;

  factory SupportTicketsSummary.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    final items = <SupportTicketItem>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          items.add(
            SupportTicketItem.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    final open = json['openCount'];
    return SupportTicketsSummary(
      openCount: open is int
          ? open
          : (open is num ? open.toInt() : 0),
      items: items,
    );
  }
}

class AppProfileSummary {
  const AppProfileSummary({
    this.location = '',
    this.tech = '',
    this.rolesOfInterest = '',
    this.newsTopics = '',
    this.learningTime = '',
    this.displayName = '',
    this.experience = '',
    this.workAuthorization = '',
  });

  final String location;
  final String tech;
  final String rolesOfInterest;
  final String newsTopics;
  final String learningTime;
  final String displayName;
  final String experience;
  final String workAuthorization;

  factory AppProfileSummary.fromJson(Map<String, dynamic> json) {
    return AppProfileSummary(
      location: '${json['location'] ?? ''}'.trim(),
      tech: '${json['tech'] ?? ''}'.trim(),
      rolesOfInterest: '${json['rolesOfInterest'] ?? ''}'.trim(),
      newsTopics: '${json['newsTopics'] ?? ''}'.trim(),
      learningTime: '${json['learningTime'] ?? ''}'.trim(),
      displayName: '${json['displayName'] ?? ''}'.trim(),
      experience: '${json['experience'] ?? ''}'.trim(),
      workAuthorization: '${json['workAuthorization'] ?? ''}'.trim(),
    );
  }
}

class PlanBenefitChipRemote {
  const PlanBenefitChipRemote({
    required this.key,
    required this.title,
    this.status = '',
    this.useBy = '',
    this.formUrl = '',
    this.included = true,
  });

  final String key;
  final String title;
  final String status;
  final String useBy;
  final String formUrl;
  final bool included;

  factory PlanBenefitChipRemote.fromJson(Map<String, dynamic> json) {
    return PlanBenefitChipRemote(
      key: '${json['key'] ?? ''}'.trim(),
      title: '${json['title'] ?? ''}'.trim(),
      status: '${json['status'] ?? ''}'.trim(),
      useBy: '${json['useBy'] ?? ''}'.trim(),
      formUrl: '${json['formUrl'] ?? ''}'.trim(),
      included: json['included'] != false,
    );
  }
}

class PlanBenefitsSummary {
  const PlanBenefitsSummary({
    this.plan = '',
    this.useBy = '',
    this.whatsappGroupUrl = '',
    this.chips = const [],
  });

  final String plan;
  final String useBy;
  final String whatsappGroupUrl;
  final List<PlanBenefitChipRemote> chips;

  factory PlanBenefitsSummary.fromJson(Map<String, dynamic> json) {
    final raw = json['chips'];
    final chips = <PlanBenefitChipRemote>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          chips.add(
            PlanBenefitChipRemote.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    return PlanBenefitsSummary(
      plan: '${json['plan'] ?? ''}'.trim(),
      useBy: '${json['useBy'] ?? ''}'.trim(),
      whatsappGroupUrl: '${json['whatsappGroupUrl'] ?? ''}'.trim(),
      chips: chips,
    );
  }
}

class CalendarHoliday {
  const CalendarHoliday({required this.dateKey, required this.name});
  final String dateKey;
  final String name;

  factory CalendarHoliday.fromJson(Map<String, dynamic> json) {
    return CalendarHoliday(
      dateKey: '${json['dateKey'] ?? json['date'] ?? ''}'.trim(),
      name: '${json['name'] ?? ''}'.trim(),
    );
  }
}
