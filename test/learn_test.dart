import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:firststep_mobile/features/learn/learn_store.dart';
import 'package:firststep_mobile/features/learn/learn_view.dart';
import 'package:firststep_mobile/features/learn/screens/learn_screens.dart';
import 'package:firststep_mobile/theme/home_tokens.dart';

void main() {
  Widget host() {
    return MaterialApp(
      theme: ThemeData.light().copyWith(extensions: [HomeTokens.light]),
      home: const Scaffold(body: LearnTab()),
    );
  }

  testWidgets('Learn shows week card and question of the day', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(host());
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('This week'), findsOneWidget);
    expect(find.text('10 questions: SQL & Python'), findsOneWidget);
    expect(find.text('Question of the Day'), findsOneWidget);
    expect(find.text('DENSE_RANK()'), findsOneWidget);
  });

  test('answering QOD stores the mint option', () {
    final store = LearnStore();
    expect(store.qodAnswered, isFalse);
    store.answerQod(1);
    expect(store.qodAnswered, isTrue);
    expect(store.qodPicked, 1);
  });

  test('answerQod applies API streak when provided', () {
    final store = LearnStore(signedIn: true);
    store.answerQod(0, correct: true, explanation: 'Yes', streak: 12);
    expect(store.content.streak, 12);
    expect(store.qodWasCorrect, isTrue);
  });

  testWidgets('correct QOD tap reveals the explanation', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(host());
    await tester.pump(const Duration(milliseconds: 200));

    final option = find.text('DENSE_RANK()');
    await tester.ensureVisible(option);
    await tester.pump();
    await tester.tap(option);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Ties share a rank'), findsOneWidget);
  });

  testWidgets('share story submit clears system nav inset', (tester) async {
    const size = Size(390, 844);
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    // Simulate Android 3-button / gesture nav under the sheet.
    tester.view.padding = const FakeViewPadding(bottom: 48);
    tester.view.viewPadding = const FakeViewPadding(bottom: 48);
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetPadding();
      tester.view.resetViewPadding();
    });

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.light().copyWith(extensions: [HomeTokens.light]),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => openShareStory(context),
            child: const Text('Open share'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Open share'));
    await tester.pumpAndSettle();

    expect(find.text('Submit for review'), findsOneWidget);
    final button = tester.getRect(find.text('Submit for review'));
    // Button bottom must sit above the 48px system nav inset.
    expect(button.bottom, lessThanOrEqualTo(size.height - 48));
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Submit for review'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('preview flask switches to no-role week card', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(host());
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.byTooltip('Preview states'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Basic · no role set'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.text('Pick your role to get weekly questions'),
      findsOneWidget,
    );
    expect(
      find.text('Add your role in Profile to get picks for you'),
      findsOneWidget,
    );
  });
}
