import 'package:flutter_test/flutter_test.dart';
import 'package:rever_chat/models/validated_order.dart';

void main() {
  group('ValidatedOrder', () {
    test('giftCardValue applies 10% bonus', () {
      final order = ValidatedOrder(
        orderId: '1',
        email: 'a@b.com',
        productTitle: 'Jacket',
        productVariant: 'M',
        total: 100.00,
        currency: 'EUR',
      );
      expect(order.giftCardValue, closeTo(110.00, 0.001));
    });

    test('giftCardValue rounds to 2 decimal places', () {
      final order = ValidatedOrder(
        orderId: '1',
        email: 'a@b.com',
        productTitle: 'Sneakers',
        productVariant: '42',
        total: 49.99,
        currency: 'EUR',
      );
      // 49.99 * 1.10 = 54.989 -> 54.99
      expect(order.giftCardValue, closeTo(54.99, 0.001));
    });

    test('giftCardValue for zero total is zero', () {
      final order = ValidatedOrder(
        orderId: '1',
        email: 'a@b.com',
        productTitle: 'Free Gift',
        productVariant: 'One Size',
        total: 0.0,
        currency: 'EUR',
      );
      expect(order.giftCardValue, 0.0);
    });

    test('formattedTotal returns amount with currency', () {
      final order = ValidatedOrder(
        orderId: '1',
        email: 'a@b.com',
        productTitle: 'T-Shirt',
        productVariant: 'S',
        total: 29.99,
        currency: 'EUR',
      );
      expect(order.formattedTotal, '29.99 EUR');
    });

    test('formattedGiftCard returns gift card value with currency', () {
      final order = ValidatedOrder(
        orderId: '1',
        email: 'a@b.com',
        productTitle: 'T-Shirt',
        productVariant: 'S',
        total: 100.00,
        currency: 'USD',
      );
      expect(order.formattedGiftCard, '110.00 USD');
    });

    test('formattedTotal formats to 2 decimal places', () {
      final order = ValidatedOrder(
        orderId: '1',
        email: 'a@b.com',
        productTitle: 'Shorts',
        productVariant: 'M',
        total: 30.0,
        currency: 'GBP',
      );
      expect(order.formattedTotal, '30.00 GBP');
    });

    test('giftCardValue is greater than total', () {
      final order = ValidatedOrder(
        orderId: '1',
        email: 'a@b.com',
        productTitle: 'Hat',
        productVariant: 'S',
        total: 55.00,
        currency: 'EUR',
      );
      expect(order.giftCardValue, greaterThan(order.total));
    });

    test('bonus amount (giftCard - total) equals 10% of total', () {
      final order = ValidatedOrder(
        orderId: '1',
        email: 'a@b.com',
        productTitle: 'Bag',
        productVariant: 'Black',
        total: 80.00,
        currency: 'EUR',
      );
      final bonus = order.giftCardValue - order.total;
      expect(bonus, closeTo(8.00, 0.001));
    });
  });
}
