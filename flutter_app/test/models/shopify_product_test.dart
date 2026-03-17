import 'package:flutter_test/flutter_test.dart';
import 'package:rever_chat/models/shopify_product.dart';

Map<String, dynamic> _buildGraphQLNode({
  String id = 'gid://shopify/Product/1',
  String title = 'Cool T-Shirt',
  String description = 'A great shirt',
  String handle = 'cool-t-shirt',
  bool availableForSale = true,
  String price = '29.99',
  String currency = 'EUR',
  String? imageUrl,
  String? variantId = 'gid://shopify/ProductVariant/100',
  String? compareAtPrice,
  List<String> variantTitles = const ['S', 'M', 'L'],
}) {
  return {
    'id': id,
    'title': title,
    'description': description,
    'handle': handle,
    'availableForSale': availableForSale,
    'priceRange': {
      'minVariantPrice': {'amount': price, 'currencyCode': currency},
    },
    'images': {
      'edges': imageUrl != null
          ? [
              {
                'node': {'url': imageUrl}
              }
            ]
          : [],
    },
    'variants': {
      'edges': [
        {
          'node': {
            'id': variantId,
            'title': variantTitles.isNotEmpty ? variantTitles[0] : '',
            'availableForSale': true,
            'compareAtPrice':
                compareAtPrice != null ? {'amount': compareAtPrice} : null,
          }
        },
        if (variantTitles.length > 1)
          {
            'node': {
              'id': 'gid://shopify/ProductVariant/101',
              'title': variantTitles[1],
              'availableForSale': true,
              'compareAtPrice': null,
            }
          },
        if (variantTitles.length > 2)
          {
            'node': {
              'id': 'gid://shopify/ProductVariant/102',
              'title': variantTitles[2],
              'availableForSale': false,
              'compareAtPrice': null,
            }
          },
      ],
    },
  };
}

void main() {
  group('ShopifyProduct.fromGraphQL()', () {
    test('parses all top-level string fields', () {
      final p = ShopifyProduct.fromGraphQL(_buildGraphQLNode());
      expect(p.id, 'gid://shopify/Product/1');
      expect(p.title, 'Cool T-Shirt');
      expect(p.description, 'A great shirt');
      expect(p.handle, 'cool-t-shirt');
    });

    test('parses availableForSale = true', () {
      final p = ShopifyProduct.fromGraphQL(_buildGraphQLNode());
      expect(p.availableForSale, true);
    });

    test('parses availableForSale = false', () {
      final p = ShopifyProduct.fromGraphQL(
          _buildGraphQLNode(availableForSale: false));
      expect(p.availableForSale, false);
    });

    test('parses price and currency', () {
      final p = ShopifyProduct.fromGraphQL(
          _buildGraphQLNode(price: '99.00', currency: 'USD'));
      expect(p.price, '99.00');
      expect(p.currencyCode, 'USD');
    });

    test('parses image URL from edges', () {
      final p = ShopifyProduct.fromGraphQL(
          _buildGraphQLNode(imageUrl: 'https://cdn.shopify.com/img.jpg'));
      expect(p.imageUrl, 'https://cdn.shopify.com/img.jpg');
    });

    test('sets imageUrl to null when edges empty', () {
      final p = ShopifyProduct.fromGraphQL(_buildGraphQLNode(imageUrl: null));
      expect(p.imageUrl, isNull);
    });

    test('parses variantId from first variant', () {
      final p = ShopifyProduct.fromGraphQL(_buildGraphQLNode());
      expect(p.variantId, 'gid://shopify/ProductVariant/100');
    });

    test('parses compareAtPrice from first variant', () {
      final p = ShopifyProduct.fromGraphQL(
          _buildGraphQLNode(compareAtPrice: '49.99'));
      expect(p.compareAtPrice, '49.99');
    });

    test('sets compareAtPrice to null when not provided', () {
      final p = ShopifyProduct.fromGraphQL(_buildGraphQLNode());
      expect(p.compareAtPrice, isNull);
    });

    test('parses variant titles list', () {
      final p = ShopifyProduct.fromGraphQL(
          _buildGraphQLNode(variantTitles: ['S', 'M', 'L']));
      expect(p.variants, containsAll(['S', 'M', 'L']));
      expect(p.variants.length, 3);
    });

    test('filters empty variant titles', () {
      final p = ShopifyProduct.fromGraphQL(
          _buildGraphQLNode(variantTitles: []));
      expect(p.variants, isEmpty);
    });

    test('handles empty node gracefully with defaults', () {
      final p = ShopifyProduct.fromGraphQL({});
      expect(p.id, '');
      expect(p.title, '');
      expect(p.price, '0.00');
      expect(p.currencyCode, 'EUR');
      expect(p.availableForSale, false);
      expect(p.variants, isEmpty);
    });
  });

  group('ShopifyProduct.formattedPrice', () {
    test('returns price + space + currencyCode', () {
      const p = ShopifyProduct(
        id: 'x',
        title: 'T',
        description: '',
        handle: 'h',
        price: '19.99',
        currencyCode: 'GBP',
        availableForSale: true,
        variants: [],
      );
      expect(p.formattedPrice, '19.99 GBP');
    });
  });

  group('ShopifyProduct.isOnSale', () {
    test('returns true when compareAtPrice > price', () {
      const p = ShopifyProduct(
        id: 'x',
        title: 'T',
        description: '',
        handle: 'h',
        price: '29.99',
        currencyCode: 'EUR',
        compareAtPrice: '49.99',
        availableForSale: true,
        variants: [],
      );
      expect(p.isOnSale, true);
    });

    test('returns false when compareAtPrice is null', () {
      const p = ShopifyProduct(
        id: 'x',
        title: 'T',
        description: '',
        handle: 'h',
        price: '29.99',
        currencyCode: 'EUR',
        availableForSale: true,
        variants: [],
      );
      expect(p.isOnSale, false);
    });

    test('returns false when compareAtPrice == price', () {
      const p = ShopifyProduct(
        id: 'x',
        title: 'T',
        description: '',
        handle: 'h',
        price: '29.99',
        currencyCode: 'EUR',
        compareAtPrice: '29.99',
        availableForSale: true,
        variants: [],
      );
      expect(p.isOnSale, false);
    });

    test('returns false when compareAtPrice < price (invalid data)', () {
      const p = ShopifyProduct(
        id: 'x',
        title: 'T',
        description: '',
        handle: 'h',
        price: '49.99',
        currencyCode: 'EUR',
        compareAtPrice: '29.99',
        availableForSale: true,
        variants: [],
      );
      expect(p.isOnSale, false);
    });

    test('returns false when compareAtPrice is non-numeric', () {
      const p = ShopifyProduct(
        id: 'x',
        title: 'T',
        description: '',
        handle: 'h',
        price: 'abc',
        currencyCode: 'EUR',
        compareAtPrice: 'xyz',
        availableForSale: true,
        variants: [],
      );
      expect(p.isOnSale, false);
    });
  });
}
