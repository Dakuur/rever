import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:shimmer/shimmer.dart';

import '../models/shopify_product.dart';
import '../theme/rever_theme.dart';

class ProductCard extends StatelessWidget {
  final ShopifyProduct product;
  final VoidCallback? onTap;

  const ProductCard({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: ReverTheme.cardBg,
          borderRadius: BorderRadius.circular(ReverTheme.radiusMedium),
          boxShadow: ReverTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(ReverTheme.radiusMedium),
                topRight: Radius.circular(ReverTheme.radiusMedium),
              ),
              child: product.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrl!,
                      height: 130,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _imageSkeleton(),
                      errorWidget: (_, __, ___) => _imagePlaceholder(),
                    )
                  : _imagePlaceholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: ReverTheme.bodyRegular
                        .copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(product.formattedPrice,
                          style: ReverTheme.bodyRegular.copyWith(
                              color: ReverTheme.accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: product.availableForSale
                              ? ReverTheme.success.withValues(alpha: 0.12)
                              : ReverTheme.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product.availableForSale
                              ? 'In stock'
                              : 'Out of stock',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: product.availableForSale
                                ? ReverTheme.success
                                : ReverTheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
        height: 130,
        color: ReverTheme.surface,
        child: const Center(
          child: Icon(CupertinoIcons.bag, color: ReverTheme.textSecondary, size: 32),
        ),
      );

  Widget _imageSkeleton() => Shimmer.fromColors(
        baseColor: const Color(0xFFE5E5EA),
        highlightColor: const Color(0xFFF7F7F8),
        child: Container(height: 130, color: CupertinoColors.white),
      );
}
