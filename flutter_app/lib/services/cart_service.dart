// ignore: avoid_web_libraries_in_flutter
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Receives the customer's Shopify cart via postMessage from the parent page.
///
/// Flow:
///   Shopify page (rever-chat.liquid)
///     → fetch('/cart.js')
///     → postMessage(JSON.stringify({ type: 'rever:cart', cart }), '*')
///   Flutter (index.html listener logs it, then dart:html onMessage catches it)
///     → CartService stores _cartData
///     → buildCartContext() returns AI-readable summary
///
/// Call CartService().init() once early (e.g. in main() or ChatScreen.initState).
class CartService {
  static final CartService _instance = CartService._();
  factory CartService() => _instance;
  CartService._();

  Map<String, dynamic>? _cartData;

  /// Start listening for cart postMessages from the Shopify parent page.
  /// Safe to call multiple times (subsequent calls are no-ops).
  bool _initialised = false;
  void init() {
    if (_initialised) return;
    _initialised = true;

    html.window.onMessage.listen((event) {
      try {
        final raw = event.data;
        if (raw == null) return;

        // The liquid block sends JSON.stringify(...) so event.data is a String.
        if (raw is! String) return;

        final msg = jsonDecode(raw) as Map<String, dynamic>?;
        if (msg == null || msg['type'] != 'rever:cart') return;

        _cartData = msg['cart'] as Map<String, dynamic>?;

        final itemCount = _cartData?['item_count'] as int? ?? 0;
        final totalCents = _cartData?['total_price'] as int? ?? 0;
        final total = totalCents / 100;
        final cur = _cartData?['currency'] as String? ?? 'EUR';
        print('[CartService] Cart received: $itemCount items | $cur ${total.toStringAsFixed(2)}');
        final items = (_cartData?['items'] as List<dynamic>?) ?? [];
        for (final item in items) {
          final i = item as Map<String, dynamic>;
          final variant = (i['variant_title'] as String?) ?? '';
          final variantSuffix =
              (variant.isNotEmpty && variant != 'Default Title') ? ' ($variant)' : '';
          print('[CartService]   ↳ ${i['title']}$variantSuffix '
              'x${i['quantity']} @ $cur ${((i['price'] as int? ?? 0) / 100).toStringAsFixed(2)}');
        }
      } catch (e) {
        print('[CartService] ERROR parsing cart message: $e');
      }
    });

    print('[CartService] Listening for cart postMessage from Shopify parent');
  }

  int get itemCount => (_cartData?['item_count'] as int?) ?? 0;
  String get currency => (_cartData?['currency'] as String?) ?? 'EUR';

  /// Returns a human-readable cart summary for the AI system context.
  /// Returns empty string when cart is empty or not yet received.
  String buildCartContext() {
    final cart = _cartData;
    if (cart == null || itemCount == 0) {
      print('[CartService] Cart empty or not yet received from parent page');
      return '';
    }

    final items = (cart['items'] as List<dynamic>?) ?? [];
    final totalCents = cart['total_price'] as int? ?? 0;
    final total = totalCents / 100;

    final buf = StringBuffer("Customer's current cart:\n");
    buf.writeln('  $itemCount item(s) | Total: $currency ${total.toStringAsFixed(2)}');
    for (final raw in items) {
      final item = raw as Map<String, dynamic>;
      final priceCents = item['price'] as int? ?? 0;
      final price = priceCents / 100;
      final qty = item['quantity'] as int? ?? 1;
      final title = item['title'] as String? ?? 'Unknown';
      final variant = item['variant_title'] as String? ?? '';
      final variantSuffix =
          (variant.isNotEmpty && variant != 'Default Title') ? ' ($variant)' : '';
      buf.writeln('  - $title$variantSuffix x$qty @ $currency ${price.toStringAsFixed(2)}');
    }

    print('[CartService] Cart context built: $itemCount items, $currency ${total.toStringAsFixed(2)}');
    return buf.toString();
  }
}
