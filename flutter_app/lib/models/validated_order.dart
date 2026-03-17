/// Real product data resolved from the Shopify catalog and used across
/// the return flow. Lives in models/ so it can be imported without
/// pulling in the web-only services (shopify_service.dart → dart:html).
class ValidatedOrder {
  final String orderId;
  final String email;
  final String productTitle;
  final String productVariant;
  final double total;
  final String currency;

  const ValidatedOrder({
    required this.orderId,
    required this.email,
    required this.productTitle,
    required this.productVariant,
    required this.total,
    required this.currency,
  });

  /// Store credit value with 10% bonus applied.
  double get giftCardValue => double.parse((total * 1.10).toStringAsFixed(2));

  String get formattedTotal => '${total.toStringAsFixed(2)} $currency';
  String get formattedGiftCard => '${giftCardValue.toStringAsFixed(2)} $currency';
}
