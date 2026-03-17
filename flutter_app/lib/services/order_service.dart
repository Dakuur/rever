import 'chatbot_service.dart';
import 'shopify_service.dart';
import '../models/validated_order.dart';

export '../models/validated_order.dart';

/// Validates a return request by:
///  1. Checking email + order ID format.
///  2. Fetching the live Shopify product catalog.
///  3. Using the AI to fuzzy-match the customer's product description.
class OrderService {
  static final OrderService _instance = OrderService._();
  factory OrderService() => _instance;
  OrderService._();

  Future<ValidatedOrder?> validateOrder({
    required String orderId,
    required String email,
    required String productQuery,
  }) async {
    final cleanId = orderId.replaceAll(RegExp(r'[^0-9]'), '');
    final validEmail = email.contains('@') && email.contains('.');

    if (cleanId.isEmpty || !validEmail) {
      print('[OrderService] ERROR Invalid input -- id="$orderId" email="$email"');
      return null;
    }

    print('[OrderService] Looking up product: "$productQuery"');

    // Fetch full catalog from Shopify
    final products = await ShopifyService().getAllProducts();
    if (products.isEmpty) {
      print('[OrderService] ERROR Shopify catalog returned 0 products');
      return null;
    }

    // AI fuzzy-match the customer's description against real product titles
    final titles = products.map((p) => p.title).toList();
    final idx = await ChatbotService().identifyProduct(productQuery, titles);

    if (idx == 0 || idx > products.length) {
      print('[OrderService] ERROR No catalog match for: "$productQuery"');
      return null;
    }

    final product = products[idx - 1];
    print('[OrderService] Matched "${product.title}" -- '
        '${product.price} ${product.currencyCode}');

    return ValidatedOrder(
      orderId: cleanId,
      email: email,
      productTitle: product.title,
      productVariant: product.variants.isNotEmpty ? product.variants.first : 'Standard',
      total: double.tryParse(product.price) ?? 0.0,
      currency: product.currencyCode,
    );
  }
}
