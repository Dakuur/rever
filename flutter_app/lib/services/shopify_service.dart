import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/shopify_product.dart';

class ShopifyService {
  static final ShopifyService _instance = ShopifyService._();
  factory ShopifyService() => _instance;
  ShopifyService._();

  static const String _apiVersion = '2024-10';

  String get _endpoint =>
      'https://${AppConfig.shopifyStoreDomain}/api/$_apiVersion/graphql.json';

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-Shopify-Storefront-Access-Token': AppConfig.shopifyStorefrontToken,
      };

  // ── Search products ──────────────────────────────────────────────────────
  Future<List<ShopifyProduct>> searchProducts(String query) async {
    final tokenPreview = AppConfig.shopifyStorefrontToken.length > 8
        ? '${AppConfig.shopifyStorefrontToken.substring(0, 8)}...'
        : '(empty)';
    print('[ShopifyService] endpoint: $_endpoint');
    print('[ShopifyService] token: $tokenPreview');
    const gql = r'''
query SearchProducts($query: String!, $first: Int!) {
  products(query: $query, first: $first) {
    edges {
      node {
        id title description handle availableForSale
        priceRange {
          minVariantPrice { amount currencyCode }
        }
        images(first: 1) {
          edges { node { url } }
        }
        variants(first: 10) {
          edges { node { title availableForSale } }
        }
      }
    }
  }
}
''';
    final body = jsonEncode({
      'query': gql,
      'variables': {'query': query, 'first': 5},
    });

    final res = await http.post(
      Uri.parse(_endpoint),
      headers: _headers,
      body: body,
    );

    print('[ShopifyService] HTTP ${res.statusCode}');
    if (res.statusCode != 200) {
      print('[ShopifyService] ❌ Error body: ${res.body.substring(0, res.body.length.clamp(0, 300))}');
      return [];
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final edges =
        (data['data']?['products']?['edges'] as List<dynamic>?) ?? [];
    return edges
        .map((e) => ShopifyProduct.fromGraphQL(
            (e['node'] as Map<String, dynamic>?) ?? {}))
        .toList();
  }

  // ── Get single product by handle ─────────────────────────────────────────
  Future<ShopifyProduct?> getProductByHandle(String handle) async {
    const gql = r'''
query GetProduct($handle: String!) {
  productByHandle(handle: $handle) {
    id title description handle availableForSale
    priceRange {
      minVariantPrice { amount currencyCode }
    }
    images(first: 1) {
      edges { node { url } }
    }
    variants(first: 20) {
      edges { node { title availableForSale } }
    }
  }
}
''';
    final res = await http.post(
      Uri.parse(_endpoint),
      headers: _headers,
      body: jsonEncode({'query': gql, 'variables': {'handle': handle}}),
    );
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final node = data['data']?['productByHandle'] as Map<String, dynamic>?;
    return node != null ? ShopifyProduct.fromGraphQL(node) : null;
  }

  // ── Get all products (fallback when keyword search yields nothing) ──────────
  Future<List<ShopifyProduct>> getAllProducts({int first = 20}) async {
    const gql = r'''
query GetAllProducts($first: Int!) {
  products(first: $first) {
    edges {
      node {
        id title description handle availableForSale
        priceRange {
          minVariantPrice { amount currencyCode }
        }
        images(first: 1) {
          edges { node { url } }
        }
        variants(first: 10) {
          edges { node { title availableForSale } }
        }
      }
    }
  }
}
''';
    final res = await http.post(
      Uri.parse(_endpoint),
      headers: _headers,
      body: jsonEncode({'query': gql, 'variables': {'first': first}}),
    );
    print('[ShopifyService] getAllProducts HTTP ${res.statusCode}');
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final edges =
        (data['data']?['products']?['edges'] as List<dynamic>?) ?? [];
    return edges
        .map((e) => ShopifyProduct.fromGraphQL(
            (e['node'] as Map<String, dynamic>?) ?? {}))
        .toList();
  }

  // ── Fetch recommended product ─────────────────────────────────────────────

  static const _stopWords = {
    'si', 'sí', 'dame', 'el', 'la', 'los', 'las', 'un', 'una', 'unos', 'unas',
    'me', 'por', 'favor', 'más', 'mas', 'producto', 'productos', 'algo',
    'alguno', 'alguna', 'quiero', 'necesito', 'busco', 'hay',
    'tienes', 'que', 'qué', 'muestra', 'muéstrame', 'muestrame',
    'recomienda', 'recomiendame', 'sugiere', 'sugiéreme',
    'encuéntrame', 'encuentrame', 'añade', 'añademe', 'agrega', 'agrégame',
    'del', 'de', 'con', 'para', 'al',
    'yes', 'give', 'show', 'find', 'the', 'a', 'an', 'some',
    'please', 'add', 'buy', 'get', 'recommend', 'suggest',
    'product', 'products', 'something', 'i', 'want',
  };

  /// Extracts meaningful search keywords from the user's message,
  /// removing stop words and trigger phrases.
  String _extractKeywords(String userQuery) {
    final words = userQuery
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 1 && !_stopWords.contains(w))
        .toList();
    return words.join(' ').trim();
  }

  /// Fetches a product matching the user's intent.
  /// Tries: keyword search → tag:sale → any (with price sort).
  Future<ShopifyProduct?> fetchRecommendedProduct(String userQuery) async {
    final lower = userQuery.toLowerCase();
    final wantsExpensive = ['caro', 'mas caro', 'más caro', 'caros',
        'expensive', 'most expensive', 'priciest', 'pricey']
        .any((k) => lower.contains(k));
    final wantsCheap = ['barato', 'baratos', 'mas barato', 'más barato',
        'cheap', 'cheapest', 'precio bajo']
        .any((k) => lower.contains(k));

    final keywords = _extractKeywords(userQuery);
    print('[ShopifyService] fetchRecommendedProduct — keywords="$keywords" '
        'wantsExpensive=$wantsExpensive wantsCheap=$wantsCheap');

    const gql = r'''
query GetRecommendedProduct($query: String!, $reverse: Boolean!) {
  products(first: 1, query: $query, sortKey: PRICE, reverse: $reverse) {
    edges {
      node {
        id title description handle availableForSale
        priceRange { minVariantPrice { amount currencyCode } }
        images(first: 1) { edges { node { url } } }
        variants(first: 1) {
          edges {
            node {
              id availableForSale
              price { amount currencyCode }
              compareAtPrice { amount currencyCode }
            }
          }
        }
      }
    }
  }
}
''';

    // Build query list: keyword search first, then sale tag, then open
    final queries = <String>[];
    if (keywords.isNotEmpty) queries.add(keywords);
    if (!wantsExpensive && keywords.isEmpty) queries.add('tag:sale');
    queries.add(''); // fallback: all products

    for (final q in queries) {
      final res = await http.post(
        Uri.parse(_endpoint),
        headers: _headers,
        body: jsonEncode({
          'query': gql,
          'variables': {'query': q, 'reverse': wantsExpensive},
        }),
      );
      print('[ShopifyService] fetchRecommendedProduct (q="$q" reverse=$wantsExpensive) HTTP ${res.statusCode}');
      if (res.statusCode != 200) continue;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final edges = (data['data']?['products']?['edges'] as List<dynamic>?) ?? [];
      if (edges.isEmpty) {
        print('[ShopifyService] fetchRecommendedProduct (q="$q") → no products');
        continue;
      }
      final product = ShopifyProduct.fromGraphQL(
          (edges.first['node'] as Map<String, dynamic>?) ?? {});
      print('[ShopifyService] fetchRecommendedProduct → '
          'title="${product.title}" variantId=${product.variantId} '
          'price=${product.price} ${product.currencyCode} '
          'isOnSale=${product.isOnSale} availableForSale=${product.availableForSale}');
      if (product.variantId != null) return product;
      print('[ShopifyService] ⚠️ variantId is null — skipping');
    }
    print('[ShopifyService] ❌ fetchRecommendedProduct exhausted all queries');
    return null;
  }

  // ── Add to cart via postMessage → Shopify theme cart ─────────────────────
  /// Sends a postMessage to the Shopify parent page so it can call /cart/add.js.
  /// Waits for a rever:cartAddResult response (max 6 s) before resolving.
  Future<bool> createOrAddToCart(String variantGid) async {
    final numericId = variantGid.split('/').last;
    print('[ShopifyService] 🛒 postMessage → rever:addToCart variantId=$numericId');

    final completer = Completer<bool>();
    StreamSubscription? sub;

    sub = html.window.onMessage.listen((event) {
      try {
        final raw = event.data;
        if (raw is! String) return;
        final msg = jsonDecode(raw) as Map<String, dynamic>?;
        if (msg == null || msg['type'] != 'rever:cartAddResult') return;
        sub?.cancel();
        final success = msg['success'] as bool? ?? false;
        final error = msg['error'] as String?;
        if (error != null) print('[ShopifyService] ❌ cart/add.js: $error');
        if (!completer.isCompleted) completer.complete(success);
      } catch (_) {}
    });

    try {
      html.window.parent?.postMessage(
        jsonEncode({'type': 'rever:addToCart', 'variantId': numericId, 'quantity': 1}),
        '*',
      );
    } catch (e) {
      sub.cancel();
      print('[ShopifyService] ❌ postMessage send failed: $e');
      return false;
    }

    return completer.future.timeout(
      const Duration(seconds: 6),
      onTimeout: () {
        sub?.cancel();
        print('[ShopifyService] ⚠️ No response from parent page (timeout)');
        return false;
      },
    );
  }

  // ── Build context string for AI ───────────────────────────────────────────
  Future<String> buildProductContext(String userQuery) async {
    // Try keyword search first; fall back to full catalogue if no results.
    var products = await searchProducts(userQuery);
    if (products.isEmpty) {
      print('[ShopifyService] Keyword search empty, loading full catalogue.');
      products = await getAllProducts();
    }
    if (products.isEmpty) return '';

    final buffer = StringBuffer('Available products in the store:\n');
    for (final p in products) {
      buffer.writeln(
          '- ${p.title} | Price: ${p.formattedPrice} | '
          'In stock: ${p.availableForSale} | '
          'Variants: ${p.variants.join(', ')}');
      if (p.description.isNotEmpty) {
        buffer.writeln('  Description: ${p.description.substring(0, p.description.length.clamp(0, 200))}');
      }
    }
    return buffer.toString();
  }
}
