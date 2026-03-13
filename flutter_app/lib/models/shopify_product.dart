class ShopifyProduct {
  final String id;
  final String title;
  final String description;
  final String handle;
  final String? imageUrl;
  final String price;
  final String currencyCode;
  final bool availableForSale;
  final List<String> variants; // size/colour labels

  const ShopifyProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.handle,
    this.imageUrl,
    required this.price,
    required this.currencyCode,
    required this.availableForSale,
    required this.variants,
  });

  factory ShopifyProduct.fromGraphQL(Map<String, dynamic> node) {
    final priceRange = node['priceRange'] as Map<String, dynamic>? ?? {};
    final minPrice = priceRange['minVariantPrice'] as Map<String, dynamic>? ?? {};
    final images = node['images'] as Map<String, dynamic>? ?? {};
    final imageEdges = images['edges'] as List<dynamic>? ?? [];
    final variantsNode = node['variants'] as Map<String, dynamic>?;
    final variantEdges = (variantsNode?['edges'] as List<dynamic>?) ?? [];

    String? imageUrl;
    if (imageEdges.isNotEmpty) {
      final imgNode = imageEdges.first['node'] as Map<String, dynamic>?;
      imageUrl = imgNode?['url'] as String?;
    }

    return ShopifyProduct(
      id: node['id'] as String? ?? '',
      title: node['title'] as String? ?? '',
      description: node['description'] as String? ?? '',
      handle: node['handle'] as String? ?? '',
      imageUrl: imageUrl,
      price: minPrice['amount'] as String? ?? '0.00',
      currencyCode: minPrice['currencyCode'] as String? ?? 'EUR',
      availableForSale: node['availableForSale'] as bool? ?? false,
      variants: variantEdges
          .map((e) =>
              ((e['node'] as Map<String, dynamic>?)?['title'] as String?) ?? '')
          .where((t) => t.isNotEmpty)
          .toList(),
    );
  }

  String get formattedPrice => '$price $currencyCode';
}
