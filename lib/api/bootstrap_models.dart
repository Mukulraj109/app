/// Response shape from POST /api/me/bootstrap (subset used by mobile).
class SessionUser {
  const SessionUser({
    required this.firstName,
    required this.email,
    this.phone = '',
    this.referralCode = '',
    this.referralPoints = 0,
    this.createdAt = '',
    this.picture = '',
    this.whatsappGroupUrl = '',
  });

  final String firstName;
  final String email;
  final String phone;
  final String referralCode;
  final int referralPoints;
  final String createdAt;
  final String picture;
  final String whatsappGroupUrl;

  factory SessionUser.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const SessionUser(firstName: '', email: '');
    }
    final first = '${json['firstName'] ?? json['displayName'] ?? ''}'.trim();
    return SessionUser(
      firstName: first,
      email: '${json['email'] ?? ''}'.trim(),
      phone: '${json['phone'] ?? ''}'.trim(),
      referralCode: '${json['referralCode'] ?? ''}'.trim(),
      referralPoints: _asInt(json['referralPoints']),
      createdAt: '${json['createdAt'] ?? ''}'.trim(),
      picture: '${json['picture'] ?? ''}'.trim(),
      whatsappGroupUrl: '${json['whatsappGroupUrl'] ?? ''}'.trim(),
    );
  }

  SessionUser copyWith({
    String? firstName,
    String? email,
    String? phone,
    String? referralCode,
    int? referralPoints,
    String? createdAt,
    String? picture,
    String? whatsappGroupUrl,
  }) {
    return SessionUser(
      firstName: firstName ?? this.firstName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      referralCode: referralCode ?? this.referralCode,
      referralPoints: referralPoints ?? this.referralPoints,
      createdAt: createdAt ?? this.createdAt,
      picture: picture ?? this.picture,
      whatsappGroupUrl: whatsappGroupUrl ?? this.whatsappGroupUrl,
    );
  }

  String get displayName {
    if (firstName.isNotEmpty) return firstName;
    if (email.isNotEmpty) {
      final at = email.indexOf('@');
      return at > 0 ? email.substring(0, at) : email;
    }
    return 'Your profile';
  }

  String get initial {
    final name = displayName.trim();
    if (name.isEmpty) return '?';
    return name.substring(0, 1).toUpperCase();
  }

  /// e.g. Nov 2026
  String get memberSinceLabel {
    if (createdAt.isEmpty) return '—';
    final dt = DateTime.tryParse(createdAt);
    if (dt == null) return '—';
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
    return '${months[dt.month - 1]} ${dt.year}';
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}

class OnboardingQuestionOption {
  const OnboardingQuestionOption({required this.id, required this.label});
  final String id;
  final String label;

  factory OnboardingQuestionOption.fromJson(Map<String, dynamic> json) {
    return OnboardingQuestionOption(
      id: '${json['id'] ?? ''}'.trim(),
      label: '${json['label'] ?? json['id'] ?? ''}'.trim(),
    );
  }
}

class OnboardingQuestionSpec {
  const OnboardingQuestionSpec({
    required this.questionId,
    required this.prompt,
    required this.kind,
    this.hint = '',
    this.why = '',
    this.skippable = false,
    this.options = const [],
    this.max,
    this.maxLength,
  });

  final String questionId;
  final String prompt;
  final String kind;
  final String hint;
  final String why;
  final bool skippable;
  final List<OnboardingQuestionOption> options;
  final int? max;
  final int? maxLength;

  factory OnboardingQuestionSpec.fromJson(Map<String, dynamic> json) {
    final rawOpts = json['options'];
    final options = <OnboardingQuestionOption>[];
    if (rawOpts is List) {
      for (final item in rawOpts) {
        if (item is Map) {
          options.add(
            OnboardingQuestionOption.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    return OnboardingQuestionSpec(
      questionId: '${json['questionId'] ?? ''}'.trim(),
      prompt: '${json['prompt'] ?? ''}'.trim(),
      kind: '${json['kind'] ?? 'choice'}'.trim(),
      hint: '${json['hint'] ?? ''}'.trim(),
      why: '${json['why'] ?? ''}'.trim(),
      skippable: json['skippable'] == true,
      options: options,
      max: json['max'] is num ? (json['max'] as num).toInt() : null,
      maxLength:
          json['maxLength'] is num ? (json['maxLength'] as num).toInt() : null,
    );
  }
}

class BootstrapResult {
  const BootstrapResult({
    required this.destination,
    this.portalPath,
    this.user,
    this.questionCatalog = const [],
    this.questionOrder = const [],
    this.nextQuestion,
    this.percent = 0,
    this.selectedPlan,
  });

  final String destination;
  final String? portalPath;
  final SessionUser? user;
  final List<OnboardingQuestionSpec> questionCatalog;
  final List<String> questionOrder;
  final String? nextQuestion;
  final int percent;
  final String? selectedPlan;

  factory BootstrapResult.fromJson(Map<String, dynamic> json) {
    final destination = '${json['destination'] ?? ''}'.trim();
    final portal = json['portalPath'];
    final rawUser = json['user'];
    Map<String, dynamic>? userMap;
    if (rawUser is Map<String, dynamic>) {
      userMap = rawUser;
    } else if (rawUser is Map) {
      userMap = Map<String, dynamic>.from(rawUser);
    }

    final catalog = <OnboardingQuestionSpec>[];
    final rawCatalog = json['questionCatalog'];
    if (rawCatalog is List) {
      for (final item in rawCatalog) {
        if (item is Map) {
          catalog.add(
            OnboardingQuestionSpec.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    final order = <String>[];
    final rawOrder = json['questionOrder'];
    if (rawOrder is List) {
      for (final item in rawOrder) {
        final text = '$item'.trim();
        if (text.isNotEmpty) order.add(text);
      }
    }

    final next = json['nextQuestion'];
    final plan = json['selectedPlan'];
    return BootstrapResult(
      destination: destination,
      portalPath: portal is String ? portal : null,
      user: userMap == null ? null : SessionUser.fromJson(userMap),
      questionCatalog: catalog,
      questionOrder: order,
      nextQuestion: next is String ? next : (next == null ? null : '$next'),
      percent: SessionUser._asInt(json['percent']),
      selectedPlan: plan is String && plan.trim().isNotEmpty ? plan.trim() : null,
    );
  }

  bool get isStaffPortal => destination == 'portal';

  bool get isCandidateDestination =>
      destination == 'home' ||
      destination == 'onboarding' ||
      destination == 'checkout';

  bool get needsOnboarding => destination == 'onboarding';

  bool get needsCheckout => destination == 'checkout';
}
