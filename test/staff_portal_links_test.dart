import 'package:flutter_test/flutter_test.dart';
import 'package:firststep_mobile/auth/staff_portal_links.dart';

void main() {
  test('builds allowlisted https staff links', () {
    expect(
      staffWebsiteUrl(
        webAppOrigin: 'https://app.firststepjob.com',
        portalPath: '/super-admin/overview',
      ),
      'https://app.firststepjob.com/super-admin/overview',
    );
    expect(
      staffWebsiteUrl(
        webAppOrigin: 'https://app.firststepjob.com/',
        portalPath: '/application-incharge/dashboard',
      ),
      'https://app.firststepjob.com/application-incharge/dashboard',
    );
  });

  test('rejects unknown portal paths', () {
    expect(
      staffWebsiteUrl(
        webAppOrigin: 'https://app.firststepjob.com',
        portalPath: '/evil',
      ),
      isNull,
    );
    expect(
      staffWebsiteUrl(
        webAppOrigin: 'https://app.firststepjob.com',
        portalPath: null,
      ),
      isNull,
    );
  });

  test('built link never contains a token query', () {
    final url = staffWebsiteUrl(
      webAppOrigin: 'https://app.firststepjob.com',
      portalPath: '/job-collector/dashboard',
    )!;
    expect(url.contains('token'), isFalse);
    expect(url.startsWith('https://'), isTrue);
  });
}
