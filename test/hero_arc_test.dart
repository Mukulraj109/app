import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:firststep_mobile/features/home/home_store.dart';
import 'package:firststep_mobile/features/home/widgets/hero_arc.dart';
import 'package:firststep_mobile/theme/home_tokens.dart';

void main() {
  test('filledSegments = round(value / max * 12), clamped', () {
    expect(const HeroSpec(value: 9, max: 30).filledSegments, 4); // 3.6 -> 4
    expect(const HeroSpec(value: 27, max: 30).filledSegments, 11); // 10.8 -> 11
    expect(const HeroSpec(value: 412, max: 999).filledSegments, 5); // 4.96 -> 5
    expect(const HeroSpec(value: 150, max: 150).filledSegments, 12);
    expect(const HeroSpec(value: 900, max: 30).filledSegments, 12); // clamped
    expect(const HeroSpec(value: 40).filledSegments, 0); // no max -> 0
    expect(const HeroSpec(value: 60, max: 0).filledSegments, 0); // div-by-zero guard
  });

  testWidgets('HeroArc shows the final count and label', (tester) async {
    const spec = HeroSpec(
      value: 9,
      from: 6,
      max: 30,
      status: HeroStatus.applying,
      companies: ['Stripe', 'Capital One', 'Airbnb'],
      label: 'applications today',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light().copyWith(extensions: [HomeTokens.light]),
        home: const Scaffold(body: HeroArc(spec: spec)),
      ),
    );
    // no pumpAndSettle: the breathing ticker runs forever; the entrance
    // (700ms) is what we're actually waiting on. One long pump only advances
    // the ticker once, so walk the frames manually.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.text('9'), findsOneWidget);
    expect(find.text(' / 30'), findsOneWidget);
    expect(find.text('applications today'), findsOneWidget);
  });
}
