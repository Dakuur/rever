import 'package:flutter/cupertino.dart';

import '../models/shopify_product.dart';
import '../services/shopify_service.dart';
import '../theme/rever_theme.dart';

/// Renders inside the chat as a bot message when a sale product is found.
/// Handles add-to-cart inline with loading and success states.
class ProductOfferCard extends StatefulWidget {
  final ShopifyProduct product;
  const ProductOfferCard({super.key, required this.product});

  @override
  State<ProductOfferCard> createState() => _ProductOfferCardState();
}

class _ProductOfferCardState extends State<ProductOfferCard> {
  _CardState _state = _CardState.idle;

  Future<void> _addToCart() async {
    final variantId = widget.product.variantId;
    print('[OfferCard] 👍 User tapped "Yes, add to cart" — '
        'product="${widget.product.title}" variantId=$variantId');
    if (variantId == null) {
      print('[OfferCard] ❌ variantId is null, cannot add to cart');
      setState(() => _state = _CardState.error);
      return;
    }
    setState(() => _state = _CardState.loading);
    final ok = await ShopifyService().createOrAddToCart(variantId);
    print('[OfferCard] ${ok ? '✅ Added to cart' : '❌ Failed to add to cart'} — '
        'product="${widget.product.title}" variantId=$variantId');
    setState(() => _state = ok ? _CardState.success : _CardState.error);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final hasDiscount = p.isOnSale;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: ReverTheme.cardBg,
          borderRadius: BorderRadius.circular(ReverTheme.radiusLarge),
          border: Border.all(color: ReverTheme.divider),
          boxShadow: ReverTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Product image ────────────────────────────────────────────
            if (p.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(ReverTheme.radiusLarge)),
                child: Image.network(
                  p.imageUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Sale badge ──────────────────────────────────────
                  if (hasDiscount)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: ReverTheme.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: ReverTheme.accent.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'ON SALE',
                        style: ReverTheme.caption.copyWith(
                          color: ReverTheme.accent,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                  // ── Title ───────────────────────────────────────────
                  Text(p.title, style: ReverTheme.headingMedium),
                  const SizedBox(height: 4),

                  // ── Price ───────────────────────────────────────────
                  Row(
                    children: [
                      Text(
                        '${p.price} ${p.currencyCode}',
                        style: ReverTheme.bodyRegular.copyWith(
                          color: ReverTheme.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${p.compareAtPrice} ${p.currencyCode}',
                          style: ReverTheme.bodySmall.copyWith(
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),

                  // ── Description snippet ─────────────────────────────
                  if (p.description.isNotEmpty)
                    Text(
                      p.description.length > 100
                          ? '${p.description.substring(0, 100)}…'
                          : p.description,
                      style: ReverTheme.bodySmall,
                    ),

                  const SizedBox(height: 14),
                  Container(height: 0.5, color: ReverTheme.divider),
                  const SizedBox(height: 12),

                  // ── CTA ─────────────────────────────────────────────
                  _buildCta(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCta() {
    switch (_state) {
      case _CardState.success:
        return Row(
          children: [
            const Icon(CupertinoIcons.checkmark_circle_fill,
                color: ReverTheme.success, size: 18),
            const SizedBox(width: 8),
            Text(
              "It's in your cart!",
              style: ReverTheme.bodySmall.copyWith(
                color: ReverTheme.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );

      case _CardState.error:
        return Text(
          'Something went wrong. Please try again.',
          style: ReverTheme.bodySmall.copyWith(color: ReverTheme.error),
        );

      case _CardState.loading:
        return const Center(
          child: CupertinoActivityIndicator(
              color: ReverTheme.accent, radius: 12),
        );

      case _CardState.idle:
        if (!widget.product.availableForSale) {
          return Row(
            children: [
              const Icon(CupertinoIcons.xmark_circle,
                  color: ReverTheme.textSecondary, size: 16),
              const SizedBox(width: 6),
              Text('Out of stock',
                  style: ReverTheme.bodySmall.copyWith(
                    color: ReverTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Would you like to add this to your cart?',
              style: ReverTheme.bodySmall
                  .copyWith(color: ReverTheme.textPrimary),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                // Yes — filled blue
                Expanded(
                  child: GestureDetector(
                    onTap: _addToCart,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: ReverTheme.accent,
                        borderRadius:
                            BorderRadius.circular(ReverTheme.radiusMedium),
                        boxShadow: ReverTheme.floatingShadow,
                      ),
                      child: Center(
                        child: Text(
                          'Yes, add to cart',
                          style: ReverTheme.bodySmall.copyWith(
                            color: CupertinoColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // No — outlined
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      print('[OfferCard] 👎 User tapped "No, thanks" — product="${widget.product.title}"');
                      setState(() => _state = _CardState.dismissed);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: ReverTheme.cardBg,
                        borderRadius:
                            BorderRadius.circular(ReverTheme.radiusMedium),
                        border: Border.all(color: ReverTheme.accent),
                      ),
                      child: Center(
                        child: Text(
                          'No, thanks',
                          style: ReverTheme.bodySmall.copyWith(
                            color: ReverTheme.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );

      case _CardState.dismissed:
        return Text(
          'No problem! Let me know if I can help with anything else.',
          style: ReverTheme.bodySmall,
        );
    }
  }
}

enum _CardState { idle, loading, success, error, dismissed }
