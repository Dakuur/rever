@TestOn('browser')
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rever_chat/models/validated_order.dart';
import 'package:rever_chat/services/language_service.dart';
import 'package:rever_chat/widgets/incentive_step_card.dart';

Widget _wrap(Widget child) => CupertinoApp(home: SingleChildScrollView(child: child));

ValidatedOrder _order() => const ValidatedOrder(
      orderId: '1234',
      email: 'test@test.com',
      productTitle: 'Cool Jacket',
      productVariant: 'Size M',
      total: 89.99,
      currency: 'EUR',
    );

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    LanguageService().resetForTesting();
  });

  group('IncentiveStepCard – exchange step', () {
    testWidgets('renders exchange title', (tester) async {
      await tester.pumpWidget(_wrap(
        IncentiveStepCard(
          step: LadderStep.exchange,
          order: _order(),
          onAccepted: () {},
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Size or Colour Exchange'), findsOneWidget);
    });

    testWidgets('renders accept button for exchange', (tester) async {
      await tester.pumpWidget(_wrap(
        IncentiveStepCard(
          step: LadderStep.exchange,
          order: _order(),
          onAccepted: () {},
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Accept Exchange'), findsOneWidget);
    });

    testWidgets('renders decline button for exchange', (tester) async {
      await tester.pumpWidget(_wrap(
        IncentiveStepCard(
          step: LadderStep.exchange,
          order: _order(),
          onAccepted: () {},
          onDeclined: () {},
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text("I'd prefer something else"), findsOneWidget);
    });

    testWidgets('exchange body includes product title', (tester) async {
      await tester.pumpWidget(_wrap(
        IncentiveStepCard(
          step: LadderStep.exchange,
          order: _order(),
          onAccepted: () {},
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('Cool Jacket'), findsOneWidget);
    });

    testWidgets('calls onAccepted after tapping accept', (tester) async {
      bool accepted = false;
      await tester.pumpWidget(_wrap(
        IncentiveStepCard(
          step: LadderStep.exchange,
          order: _order(),
          onAccepted: () => accepted = true,
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Accept Exchange'));
      // Advance through the loading (600ms) and confirmed (400ms) delays
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 400));
      expect(accepted, true);
    });

    testWidgets('calls onDeclined after tapping decline', (tester) async {
      bool declined = false;
      await tester.pumpWidget(_wrap(
        IncentiveStepCard(
          step: LadderStep.exchange,
          order: _order(),
          onAccepted: () {},
          onDeclined: () => declined = true,
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text("I'd prefer something else"));
      await tester.pump(const Duration(milliseconds: 400));
      expect(declined, true);
    });
  });

  group('IncentiveStepCard – gift card step', () {
    testWidgets('renders gift card title', (tester) async {
      await tester.pumpWidget(_wrap(
        IncentiveStepCard(
          step: LadderStep.giftCard,
          order: _order(),
          onAccepted: () {},
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Store Credit + 10% Bonus'), findsOneWidget);
    });

    testWidgets('renders accept button for gift card', (tester) async {
      await tester.pumpWidget(_wrap(
        IncentiveStepCard(
          step: LadderStep.giftCard,
          order: _order(),
          onAccepted: () {},
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Accept Store Credit'), findsOneWidget);
    });

    testWidgets('renders decline button for gift card', (tester) async {
      await tester.pumpWidget(_wrap(
        IncentiveStepCard(
          step: LadderStep.giftCard,
          order: _order(),
          onAccepted: () {},
          onDeclined: () {},
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('I want a cash refund'), findsOneWidget);
    });

    testWidgets('gift card body shows original and bonus amounts', (tester) async {
      await tester.pumpWidget(_wrap(
        IncentiveStepCard(
          step: LadderStep.giftCard,
          order: _order(),
          onAccepted: () {},
        ),
      ));
      await tester.pumpAndSettle();
      // 89.99 * 1.10 = 98.99 EUR
      expect(find.textContaining('89.99 EUR'), findsOneWidget);
      expect(find.textContaining('98.99 EUR'), findsOneWidget);
    });
  });

  group('IncentiveStepCard – refund step', () {
    testWidgets('renders refund title', (tester) async {
      await tester.pumpWidget(_wrap(
        IncentiveStepCard(
          step: LadderStep.refund,
          order: _order(),
          onAccepted: () {},
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Refund to Original Payment'), findsOneWidget);
    });

    testWidgets('renders confirm refund button', (tester) async {
      await tester.pumpWidget(_wrap(
        IncentiveStepCard(
          step: LadderStep.refund,
          order: _order(),
          onAccepted: () {},
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Confirm Refund'), findsOneWidget);
    });

    testWidgets('refund step has NO decline button', (tester) async {
      await tester.pumpWidget(_wrap(
        IncentiveStepCard(
          step: LadderStep.refund,
          order: _order(),
          onAccepted: () {},
        ),
      ));
      await tester.pumpAndSettle();
      // None of the decline labels should appear
      expect(find.text("I'd prefer something else"), findsNothing);
      expect(find.text('I want a cash refund'), findsNothing);
    });

    testWidgets('refund body contains formatted total', (tester) async {
      await tester.pumpWidget(_wrap(
        IncentiveStepCard(
          step: LadderStep.refund,
          order: _order(),
          onAccepted: () {},
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('89.99 EUR'), findsOneWidget);
    });
  });

  group('IncentiveStepCard – subtitle content', () {
    testWidgets('exchange subtitle is shown', (tester) async {
      await tester.pumpWidget(_wrap(
        IncentiveStepCard(
          step: LadderStep.exchange,
          order: _order(),
          onAccepted: () {},
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Free, instant — no questions asked'), findsOneWidget);
    });

    testWidgets('refund subtitle shows business days', (tester) async {
      await tester.pumpWidget(_wrap(
        IncentiveStepCard(
          step: LadderStep.refund,
          order: _order(),
          onAccepted: () {},
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('3–5 business days'), findsOneWidget);
    });
  });
}
