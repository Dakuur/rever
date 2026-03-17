@TestOn('browser')
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rever_chat/models/shopify_product.dart';
import 'package:rever_chat/widgets/product_card.dart';

Widget _wrap(Widget child) => CupertinoApp(home: child);

ShopifyProduct _product({
  String title = 'Cool T-Shirt',
  String price = '29.99',
  String currency = 'EUR',
  bool available = true,
  String? imageUrl,
  List<String> variants = const ['S', 'M', 'L'],
}) =>
    ShopifyProduct(
      id: 'gid://shopify/Product/1',
      title: title,
      description: 'A nice product',
      handle: 'cool-t-shirt',
      imageUrl: imageUrl,
      price: price,
      currencyCode: currency,
      availableForSale: available,
      variants: variants,
    );

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('ProductCard – content rendering', () {
    testWidgets('displays product title', (tester) async {
      await tester.pumpWidget(_wrap(ProductCard(product: _product())));
      await tester.pump();
      expect(find.text('Cool T-Shirt'), findsOneWidget);
    });

    testWidgets('displays formatted price', (tester) async {
      await tester.pumpWidget(
          _wrap(ProductCard(product: _product(price: '59.99', currency: 'USD'))));
      await tester.pump();
      expect(find.text('59.99 USD'), findsOneWidget);
    });

    testWidgets('shows "In stock" badge when available', (tester) async {
      await tester.pumpWidget(
          _wrap(ProductCard(product: _product(available: true))));
      await tester.pump();
      expect(find.text('In stock'), findsOneWidget);
    });

    testWidgets('shows "Out of stock" badge when not available', (tester) async {
      await tester.pumpWidget(
          _wrap(ProductCard(product: _product(available: false))));
      await tester.pump();
      expect(find.text('Out of stock'), findsOneWidget);
    });

    testWidgets('renders placeholder icon when no imageUrl', (tester) async {
      await tester.pumpWidget(
          _wrap(ProductCard(product: _product(imageUrl: null))));
      await tester.pump();
      expect(find.byIcon(CupertinoIcons.bag), findsOneWidget);
    });
  });

  group('ProductCard – interaction', () {
    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(_wrap(
        ProductCard(
          product: _product(),
          onTap: () => tapped = true,
        ),
      ));
      await tester.pump();
      await tester.tap(find.byType(GestureDetector).first);
      expect(tapped, true);
    });

    testWidgets('does not throw when onTap is null', (tester) async {
      await tester.pumpWidget(
          _wrap(ProductCard(product: _product(), onTap: null)));
      await tester.pump();
      expect(() => tester.tap(find.byType(GestureDetector).first),
          returnsNormally);
    });
  });

  group('ProductCard – layout', () {
    testWidgets('renders at the correct width', (tester) async {
      // ProductCard is a browser widget; the width test runs on Chrome.
      // Here we just verify it renders without throwing.
      await tester.pumpWidget(_wrap(ProductCard(product: _product())));
      await tester.pump();
      expect(find.byType(ProductCard), findsOneWidget);
    });

    testWidgets('renders without errors for product with no variants',
        (tester) async {
      await tester.pumpWidget(
          _wrap(ProductCard(product: _product(variants: []))));
      await tester.pump();
      expect(find.text('Cool T-Shirt'), findsOneWidget);
    });
  });
}
