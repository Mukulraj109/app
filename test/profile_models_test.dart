import 'package:flutter_test/flutter_test.dart';

import 'package:firststep_mobile/api/bootstrap_models.dart';
import 'package:firststep_mobile/api/profile_models.dart';
import 'package:firststep_mobile/features/profile/profile_store.dart';

void main() {
  test('BootstrapResult parses session user', () {
    final result = BootstrapResult.fromJson({
      'destination': 'home',
      'user': {
        'firstName': 'Sai',
        'email': 'sai@example.com',
        'referralCode': 'ABC123',
        'referralPoints': 2,
        'createdAt': '2024-11-05T12:00:00.000Z',
      },
    });
    expect(result.user?.firstName, 'Sai');
    expect(result.user?.email, 'sai@example.com');
    expect(result.user?.displayName, 'Sai');
    expect(result.user?.initial, 'S');
    expect(result.user?.memberSinceLabel, 'Nov 2024');
  });

  test('PlanSummary and RewardsSummary parse ProfileHub fields', () {
    final plan = PlanSummary.fromJson({
      'plan': 'Premium Plus',
      'categories': ['Data Engineer', 'Analytics Engineer'],
      'paymentDue': false,
      'showRenew': true,
      'discount': true,
      'status': 'active',
      'startDate': '2026-01-01',
      'endDate': '2026-04-10',
      'daysLeft': 42,
      'daysTotal': 100,
      'progress': 58,
    });
    expect(plan.plan, 'Premium Plus');
    expect(plan.categories, ['Data Engineer', 'Analytics Engineer']);
    expect(plan.showRenew, isTrue);
    expect(plan.status, 'active');
    expect(plan.daysLeft, 42);
    expect(plan.progress, 58);

    expect(PlanSummary.fromJson({}).plan, 'Normal Plan');
    expect(PlanSummary.fromJson({'plan': null}).plan, 'Normal Plan');
    expect(PlanSummary.fromJson({'plan': 'null'}).plan, 'Normal Plan');
    expect(PlanSummary.fromJson({'plan': '  '}).plan, 'Normal Plan');

    final rewards = RewardsSummary.fromJson({
      'balanceUsd': 30,
      'referralCode': 'HELLO',
    });
    expect(rewards.balanceLabel, '\$30');
  });

  test('IntakeProfileSummary maps location, work auth, and experience', () {
    final intake = IntakeProfileSummary.fromJson({
      'submitted': true,
      'groups': {
        'location': 'Austin, TX',
        'workAuthorization': 'STEM OPT',
        'experienceYears': '3–6 years',
        'roles': ['Data Engineer'],
      },
    });
    expect(intake.location, 'Austin, TX');
    expect(intake.workAuthorization, 'STEM OPT');
    expect(intake.experience, '3–6 years');
    expect(intake.rolesOfInterest, 'Data Engineer');
  });

  test('ProfileStore hydrates name, plan, rewards, and roles', () {
    final store = ProfileStore();
    store.applySessionUser(
      const SessionUser(firstName: 'Sai', email: 'sai@example.com'),
    );
    store.applyRemote(
      user: const SessionUser(
        firstName: 'Sai',
        email: 'sai@example.com',
        createdAt: '2025-06-01T00:00:00.000Z',
      ),
      planSummary: const PlanSummary(
        plan: 'Premium',
        categories: ['Data Engineer'],
        endDate: '2026-04-10',
        daysLeft: 30,
        progress: 0.7,
      ),
      documents: const DocumentsSummary(
        uploadedCount: 3,
        items: [],
      ),
      rewards: const RewardsSummary(balanceUsd: 30),
      badges: const [
        BadgeItem(key: 'a', title: 'A', earned: true),
        BadgeItem(key: 'b', title: 'B', earned: false),
      ],
      intake: const IntakeProfileSummary(
        location: 'Austin, TX',
        tech: 'SQL, Python',
        workAuthorization: 'STEM OPT',
        experience: '3–6 years',
      ),
    );

    expect(store.content.name, 'Sai');
    expect(store.content.email, 'sai@example.com');
    expect(store.content.planName, 'Premium');
    expect(store.plan, ProfilePlan.premium);
    expect(store.content.roles, ['Data Engineer']);
    expect(store.content.rewards, '\$30');
    expect(store.content.badges, 1);
    expect(store.location, 'Austin, TX');
    expect(store.workAuthorization, 'STEM OPT');
    expect(store.experience, '3–6 years');
    expect(store.content.showBenefitChips, isTrue);
    expect(store.content.memberSince, 'Jun 2025');
    expect(store.content.midStat, '3');
    expect(store.content.daysLeft, '30 days left');
  });

  test('mapPlanType covers Premium Plus and basic', () {
    expect(ProfileStore.mapPlanType('PremiumPlus'), ProfilePlan.premiumPlus);
    expect(ProfileStore.mapPlanType('Normal Plan'), ProfilePlan.basic);
    expect(ProfileStore.mapPlanType('Elite'), ProfilePlan.elite);
  });
}
