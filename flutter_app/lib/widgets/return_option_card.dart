import 'package:flutter/cupertino.dart';
import '../theme/rever_theme.dart';

enum ReturnOption { sizeExchange, giftCard, refund }

class ReturnOptionCard extends StatelessWidget {
  final ReturnOption option;
  final VoidCallback onSelected;
  final bool isSelected;

  const ReturnOptionCard({
    super.key,
    required this.option,
    required this.onSelected,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = _configs[option]!;
    return GestureDetector(
      onTap: onSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? ReverTheme.accentLight : ReverTheme.cardBgRaised,
          borderRadius: BorderRadius.circular(ReverTheme.radiusMedium),
          border: Border.all(
            color: isSelected
                ? ReverTheme.accent
                : ReverTheme.divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: config['bgColor'] as Color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                config['icon'] as IconData,
                color: config['iconColor'] as Color,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        config['title'] as String,
                        style: ReverTheme.headingMedium.copyWith(fontSize: 14),
                      ),
                      if (config['badge'] != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: ReverTheme.success,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            config['badge'] as String,
                            style: ReverTheme.caption.copyWith(
                              color: CupertinoColors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    config['subtitle'] as String,
                    style: ReverTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(CupertinoIcons.checkmark_circle_fill,
                  color: ReverTheme.accent, size: 20),
          ],
        ),
      ),
    );
  }

  static const Map<ReturnOption, Map<String, Object?>> _configs = {
    ReturnOption.sizeExchange: {
      'icon': CupertinoIcons.arrow_2_squarepath,
      'bgColor': Color(0xFFE8F4FF),
      'iconColor': ReverTheme.accent,
      'title': 'Size / Colour Exchange',
      'subtitle': 'Same item, different size or colour',
      'badge': null,
    },
    ReturnOption.giftCard: {
      'icon': CupertinoIcons.gift,
      'bgColor': Color(0xFFFFF3E0),
      'iconColor': Color(0xFFFF9F0A),
      'title': 'Gift Card',
      'subtitle': 'Receive a gift card + €5 bonus',
      'badge': '+€5 BONUS',
    },
    ReturnOption.refund: {
      'icon': CupertinoIcons.arrow_uturn_left,
      'bgColor': Color(0xFFFFEBEE),
      'iconColor': ReverTheme.error,
      'title': 'Refund',
      'subtitle': 'Full refund to your original payment method',
      'badge': null,
    },
  };
}
