import 'dart:convert';
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

    if (res.statusCode != 200) return [];
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

  // ── Build context string for Gemini ──────────────────────────────────────
  Future<String> buildProductContext(String userQuery) async {
    final products = await searchProducts(userQuery);
    if (products.isEmpty) return 'No products found matching the query.';
    final buffer = StringBuffer('Available products:\n');
    for (final p in products) {
      buffer.writeln(
          '- ${p.title} | Price: ${p.formattedPrice} | '
          'Available: ${p.availableForSale} | '
          'Variants: ${p.variants.join(', ')}');
      if (p.description.isNotEmpty) {
        buffer.writeln('  Description: ${p.description.substring(0, p.description.length.clamp(0, 200))}');
      }
    }
    return buffer.toString();
  }
}
