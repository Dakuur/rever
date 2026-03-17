import 'package:flutter_test/flutter_test.dart';
import 'package:rever_chat/l10n/app_strings.dart';
import 'package:rever_chat/models/validated_order.dart';

void main() {
  const supportedCodes = ['en', 'es', 'fr', 'de', 'pt', 'it', 'nl'];

  group('AppStrings.of()', () {
    test('creates English instance for "en"', () {
      final s = AppStrings.of('en');
      expect(s.langCode, 'en');
    });

    test('creates Spanish instance for "es"', () {
      expect(AppStrings.of('es').langCode, 'es');
    });

    test('creates French instance for "fr"', () {
      expect(AppStrings.of('fr').langCode, 'fr');
    });

    test('creates German instance for "de"', () {
      expect(AppStrings.of('de').langCode, 'de');
    });

    test('creates Portuguese instance for "pt"', () {
      expect(AppStrings.of('pt').langCode, 'pt');
    });

    test('creates Italian instance for "it"', () {
      expect(AppStrings.of('it').langCode, 'it');
    });

    test('creates Dutch instance for "nl"', () {
      expect(AppStrings.of('nl').langCode, 'nl');
    });

    test('defaults to English for unknown code', () {
      expect(AppStrings.of('zh').langCode, 'en');
    });

    test('defaults to English for empty string', () {
      expect(AppStrings.of('').langCode, 'en');
    });
  });

  group('AppStrings – all languages have non-empty strings', () {
    for (final code in supportedCodes) {
      group('[$code]', () {
        late AppStrings s;

        setUp(() {
          s = AppStrings.of(code);
        });

        test('welcomePrePurchase is non-empty', () {
          expect(s.welcomePrePurchase, isNotEmpty);
        });

        test('genericError is non-empty', () {
          expect(s.genericError, isNotEmpty);
        });

        test('noProductsFound is non-empty', () {
          expect(s.noProductsFound, isNotEmpty);
        });

        test('inputPlaceholder is non-empty', () {
          expect(s.inputPlaceholder, isNotEmpty);
        });

        test('exchangeTitle is non-empty', () {
          expect(s.exchangeTitle, isNotEmpty);
        });

        test('exchangeAcceptLabel is non-empty', () {
          expect(s.exchangeAcceptLabel, isNotEmpty);
        });

        test('exchangeDeclineLabel is non-empty', () {
          expect(s.exchangeDeclineLabel, isNotEmpty);
        });

        test('giftCardTitle is non-empty', () {
          expect(s.giftCardTitle, isNotEmpty);
        });

        test('giftCardAcceptLabel is non-empty', () {
          expect(s.giftCardAcceptLabel, isNotEmpty);
        });

        test('refundTitle is non-empty', () {
          expect(s.refundTitle, isNotEmpty);
        });

        test('refundAcceptLabel is non-empty', () {
          expect(s.refundAcceptLabel, isNotEmpty);
        });

        test('languageName is non-empty', () {
          expect(s.languageName, isNotEmpty);
        });

        test('bannerText is non-empty', () {
          expect(s.bannerText, isNotEmpty);
        });

        test('cardDecliningText is non-empty', () {
          expect(s.cardDecliningText, isNotEmpty);
        });
      });
    }
  });

  group('AppStrings – dynamic string interpolation', () {
    test('exchangeBody interpolates product title and variant', () {
      final s = AppStrings.of('en');
      final body = s.exchangeBody('Cool Jacket', 'Size M');
      expect(body, contains('Cool Jacket'));
      expect(body, contains('Size M'));
    });

    test('giftCardBody interpolates all amounts', () {
      final s = AppStrings.of('en');
      final body = s.giftCardBody(
        formattedTotal: '50.00 EUR',
        formattedGiftCard: '55.00 EUR',
        extraAmount: '5.00',
        currency: 'EUR',
      );
      expect(body, contains('50.00 EUR'));
      expect(body, contains('55.00 EUR'));
      expect(body, contains('5.00'));
    });

    test('refundBody interpolates total amount', () {
      final s = AppStrings.of('en');
      final body = s.refundBody('99.00 EUR');
      expect(body, contains('99.00 EUR'));
    });

    test('exchangeBody works in Spanish', () {
      final s = AppStrings.of('es');
      final body = s.exchangeBody('Chaqueta Azul', 'Talla L');
      expect(body, contains('Chaqueta Azul'));
      expect(body, contains('Talla L'));
    });

    test('giftCardBody works in German', () {
      final s = AppStrings.of('de');
      final body = s.giftCardBody(
        formattedTotal: '80.00 EUR',
        formattedGiftCard: '88.00 EUR',
        extraAmount: '8.00',
        currency: 'EUR',
      );
      expect(body, contains('80.00 EUR'));
      expect(body, contains('88.00 EUR'));
    });
  });

  group('AppStrings – English strings contain expected keywords', () {
    late AppStrings s;
    setUp(() => s = AppStrings.of('en'));

    test('welcomePrePurchase mentions REVER', () {
      expect(s.welcomePrePurchase.toLowerCase(), contains('rever'));
    });

    test('exchangeTitle mentions exchange concept', () {
      expect(
        s.exchangeTitle.toLowerCase(),
        anyOf(contains('exchange'), contains('colour'), contains('size')),
      );
    });

    test('giftCardTitle mentions bonus', () {
      expect(s.giftCardTitle.toLowerCase(), contains('bonus'));
    });

    test('refundTitle mentions refund', () {
      expect(s.refundTitle.toLowerCase(), contains('refund'));
    });
  });

  group('ValidatedOrder with AppStrings – gift card amount in body', () {
    test('giftCardBody reflects 10% extra from ValidatedOrder', () {
      final order = ValidatedOrder(
        orderId: '123',
        email: 'x@y.com',
        productTitle: 'T-Shirt',
        productVariant: 'M',
        total: 50.00,
        currency: 'EUR',
      );
      final s = AppStrings.of('en');
      final extraAmount = (order.giftCardValue - order.total).toStringAsFixed(2);
      final body = s.giftCardBody(
        formattedTotal: order.formattedTotal,
        formattedGiftCard: order.formattedGiftCard,
        extraAmount: extraAmount,
        currency: order.currency,
      );
      expect(body, contains('50.00 EUR'));
      expect(body, contains('55.00 EUR'));
      expect(body, contains('5.00'));
    });
  });
}
