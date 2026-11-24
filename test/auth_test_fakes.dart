import 'package:firststep_mobile/api/api_client.dart';
import 'package:firststep_mobile/api/bootstrap_models.dart';
import 'package:firststep_mobile/api/profile_models.dart';
import 'package:firststep_mobile/auth/auth_config.dart';
import 'package:firststep_mobile/auth/auth_controller.dart';
import 'package:firststep_mobile/auth/auth_service.dart';

class FakeAuthService implements AuthService {
  AuthCredentials? stored;
  String? lastConnection;
  int loginCalls = 0;

  @override
  Future<void> clearCredentials() async {
    stored = null;
  }

  @override
  Future<AuthCredentials> loginWithConnection(String connection) async {
    loginCalls += 1;
    lastConnection = connection;
    stored = const AuthCredentials(idToken: 'id.token.value');
    return stored!;
  }

  @override
  Future<void> logout() async {
    stored = null;
  }

  @override
  Future<AuthCredentials> refresh() async {
    stored ??= const AuthCredentials(idToken: 'id.token.value');
    return stored!;
  }

  @override
  Future<AuthCredentials?> restore() async => stored;
}

class FakeApiClient extends ApiClient {
  FakeApiClient({
    required super.config,
    required super.authService,
    this.result = const BootstrapResult(destination: 'home'),
    this.planSummary = const PlanSummary(plan: 'Premium'),
    this.rewards = const RewardsSummary(balanceUsd: 30),
    this.badges = const [
      BadgeItem(key: 'a', title: 'A', earned: true),
      BadgeItem(key: 'b', title: 'B', earned: true),
      BadgeItem(key: 'c', title: 'C', earned: true),
    ],
    this.intake = const IntakeProfileSummary(
      submitted: true,
      location: 'Austin, TX',
      tech: 'SQL, Python',
      rolesOfInterest: 'Data Engineer, Analytics Engineer',
    ),
  });

  BootstrapResult result;
  PlanSummary planSummary;
  RewardsSummary rewards;
  List<BadgeItem> badges;
  IntakeProfileSummary intake;
  int bootstrapCalls = 0;

  @override
  Future<BootstrapResult> bootstrap({
    String? referralCode,
    String entry = 'signup',
  }) async {
    bootstrapCalls += 1;
    return result;
  }

  @override
  Future<Map<String, dynamic>> lookupReferral(String code) async =>
      {'found': false};

  @override
  Future<PlanSummary> getPlanSummary() async => planSummary;

  @override
  Future<RewardsSummary> getRewards() async => rewards;

  @override
  Future<List<BadgeItem>> getBadges() async => badges;

  @override
  Future<IntakeProfileSummary> getIntakeProfile() async => intake;

  @override
  Future<DocumentsSummary> getDocuments() async =>
      const DocumentsSummary(uploadedCount: 0, items: []);

  @override
  Future<SupportTicketsSummary> getSupportTickets() async =>
      const SupportTicketsSummary(openCount: 0, items: []);

  @override
  Future<PlanBenefitsSummary> getPlanBenefits() async =>
      const PlanBenefitsSummary();

  @override
  Future<PlanDetailsInfo> getPlanDetails() async =>
      const PlanDetailsInfo(plan: 'Premium', description: '', features: []);

  @override
  Future<AppProfileSummary> getAppProfile() async =>
      const AppProfileSummary();

  @override
  Future<List<String>> getDoNotApply() async => const [];

  @override
  Future<List<String>> putDoNotApply(List<String> companies) async => companies;

  @override
  Future<RewardsSummary> redeemRewards({
    double amountUsd = 15,
    String addOn = 'Resume add-on',
    String previousReferralCode = '',
  }) async {
    final next = (rewards.balanceUsd - amountUsd).clamp(0, double.infinity);
    final code = rewards.referralCode.isNotEmpty
        ? rewards.referralCode
        : previousReferralCode;
    rewards = RewardsSummary(
      balanceUsd: next.toDouble(),
      referralCode: code,
    );
    return rewards;
  }

  @override
  Future<Map<String, dynamic>> getSettings() async => {
        'paid': true,
        'timezone': 'America/New_York',
        'preferences': {
          'immigration': true,
          'aiNews': true,
          'jobTips': true,
          'industry': true,
          'learning': true,
          'jobUpdates': true,
        },
        'notifications': {},
        'whatsappOptIn': {'requested': false, 'confirmed': false},
      };

  @override
  Future<Map<String, dynamic>> putSettings(Map<String, dynamic> body) async =>
      getSettings();
}

AuthConfig testAuthConfig({bool githubEnabled = false}) => AuthConfig(
      domain: 'auth.example.com',
      clientId: 'mobile-client',
      apiBaseUrl: 'https://api.example.com',
      webAppUrl: 'https://app.firststepjob.com',
      scheme: 'firststep',
      githubEnabled: githubEnabled,
      whatsappUrl: '',
    );

AuthController testAuthController({
  FakeAuthService? authService,
  FakeApiClient? apiClient,
  BootstrapResult? bootstrapResult,
}) {
  final config = testAuthConfig();
  final service = authService ?? FakeAuthService();
  final api = apiClient ??
      FakeApiClient(
        config: config,
        authService: service,
        result: bootstrapResult ?? const BootstrapResult(destination: 'home'),
      );
  return AuthController(config: config, authService: service, apiClient: api);
}
