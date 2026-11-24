import 'package:flutter_test/flutter_test.dart';

import 'package:firststep_mobile/features/profile/profile_helpers.dart';

void main() {
  group('planStatusChipLabel', () {
    test('basic plan is Free', () {
      expect(
        planStatusChipLabel(
          isBasic: true,
          paymentDue: false,
          showRenew: false,
          status: 'active',
        ),
        'Free',
      );
    });

    test('payment due wins over renew and active', () {
      expect(
        planStatusChipLabel(
          isBasic: false,
          paymentDue: true,
          showRenew: true,
          status: 'active',
        ),
        'Payment due',
      );
    });

    test('renew when showRenew and not payment due', () {
      expect(
        planStatusChipLabel(
          isBasic: false,
          paymentDue: false,
          showRenew: true,
          status: 'active',
        ),
        'Renew',
      );
    });

    test('inactive status surfaces when not due/renew', () {
      expect(
        planStatusChipLabel(
          isBasic: false,
          paymentDue: false,
          showRenew: false,
          status: 'inactive',
        ),
        'Inactive',
      );
    });

    test('default Active for paid healthy plans', () {
      expect(
        planStatusChipLabel(
          isBasic: false,
          paymentDue: false,
          showRenew: false,
          status: 'active',
        ),
        'Active',
      );
    });
  });

  group('ianaForUtcOffset', () {
    test('maps common offsets', () {
      expect(ianaForUtcOffset(Duration.zero), 'UTC');
      expect(ianaForUtcOffset(const Duration(hours: 5, minutes: 30)), 'Asia/Kolkata');
      expect(ianaForUtcOffset(const Duration(hours: 5, minutes: 45)), 'Asia/Kathmandu');
      expect(ianaForUtcOffset(const Duration(hours: 1)), 'Europe/Berlin');
      expect(ianaForUtcOffset(const Duration(hours: 8)), 'Asia/Singapore');
      expect(ianaForUtcOffset(const Duration(hours: 9)), 'Asia/Tokyo');
      expect(ianaForUtcOffset(const Duration(hours: -6)), 'America/Chicago');
      expect(ianaForUtcOffset(const Duration(hours: -3)), 'America/Sao_Paulo');
      expect(ianaForUtcOffset(const Duration(hours: -8)), 'America/Los_Angeles');
      expect(ianaForUtcOffset(const Duration(hours: -7)), 'America/Los_Angeles');
    });

    test('unknown offset falls back to America/New_York', () {
      expect(
        ianaForUtcOffset(const Duration(hours: 4, minutes: 17)),
        'America/New_York',
      );
    });
  });

  group('badgeRowsForSheet', () {
    test('keeps empty API list instead of samples', () {
      expect(
        badgeRowsForSheet<String>(const [], samples: const ['demo']),
        isEmpty,
      );
    });

    test('uses samples only when apiRows is null', () {
      expect(
        badgeRowsForSheet<String>(null, samples: const ['demo']),
        ['demo'],
      );
    });

    test('keeps non-empty API rows', () {
      expect(
        badgeRowsForSheet<String>(const ['a'], samples: const ['demo']),
        ['a'],
      );
    });
  });
}
