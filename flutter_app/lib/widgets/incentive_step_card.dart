import 'package:flutter/cupertino.dart';

import '../services/order_service.dart';
import '../theme/rever_theme.dart';

enum LadderStep { exchange, giftCard, refund }

/// A single step in the returns incentive ladder.
///
/// Shown sequentially — Exchange first, then Gift Card, then Refund.
/// The parent controls advancement; this widget only manages its own
/// loading / confirmed visual state after a button tap.
class IncentiveStepCard extends StatefulWidget {
  final LadderStep step;
  final ValidatedOrder order;
  final VoidCallback onAccepted;
  final VoidCallback? onDeclined; // null on the refund step (no fallback)

  const IncentiveStepCard({
    super.key,
    required this.step,
    required this.order,
    required this.onAccepted,
    this.onDeclined,
  });

  @override
  State<IncentiveStepCard> createState() => _IncentiveStepCardState();
}

class _IncentiveStepCardState extends State<IncentiveStepCard>
    with SingleTickerProviderStateMixin {
  _CardStatus _status = _CardStatus.idle;
  late final AnimationController _fadeIn;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _fadeIn = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..forward();
    _opacity = CurvedAnimation(parent: _fadeIn, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeIn.dispose();
    super.dispose();
  }

  Future<void> _handleAccept() async {
    setState(() => _status = _CardStatus.loading);
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() => _status = _CardStatus.confirmed);
    await Future.delayed(const Duration(milliseconds: 400));
    widget.onAccepted();
  }

  void _handleDecline() {
    setState(() => _status = _CardStatus.declined);
    Future.delayed(const Duration(milliseconds: 300), () {
      widget.onDeclined?.call();
    });
  }

  // ── Content per step ──────────────────────────────────────────────────────

  _StepContent get _content {
    final o = widget.order;
    switch (widget.step) {
      case LadderStep.exchange:
        return _StepContent(
          icon: CupertinoIcons.arrow_2_squarepath,
          iconBg: ReverTheme.accentLight,
          iconColor: ReverTheme.accent,
          title: 'Size or Colour Exchange',
          subtitle: 'Free, instant — no questions asked',
          body:
              'We\'ll swap your ${o.productTitle} (${o.productVariant}) for any '
              'other available size or colour.',
          acceptLabel: 'Accept Exchange',
          declineLabel: 'I\'d prefer something else',
          confirmedText: 'Exchange requested! ✓',
        );
      case LadderStep.giftCard:
        return _StepContent(
          icon: CupertinoIcons.gift,
          iconBg: const Color(0xFFFFF3E0),
          iconColor: const Color(0xFFFF9F0A),
          title: 'Store Credit + 10% Bonus',
          subtitle: 'Worth more than a standard refund',
          body:
              'Instead of ${o.formattedTotal} back to your card, get '
              '${o.formattedGiftCard} in store credit — that\'s '
              '${o.giftCardValue.toStringAsFixed(2) != o.total.toStringAsFixed(2) ? (o.giftCardValue - o.total).toStringAsFixed(2) : ''} '
              '${o.currency} extra.',
          acceptLabel: 'Accept Store Credit',
          declineLabel: 'I want a cash refund',
          confirmedText: 'Store credit on its way! ✓',
        );
      case LadderStep.refund:
        return _StepContent(
          icon: CupertinoIcons.creditcard,
          iconBg: const Color(0xFFFFEBEE),
          iconColor: ReverTheme.error,
          title: 'Refund to Original Payment',
          subtitle: '3–5 business days',
          body:
              '${o.formattedTotal} will be returned to your original payment method.',
          acceptLabel: 'Confirm Refund',
          declineLabel: null,
          confirmedText: 'Refund submitted ✓',
        );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Container(
          decoration: BoxDecoration(
            color: ReverTheme.cardBg,
            borderRadius: BorderRadius.circular(ReverTheme.radiusLarge),
            border: Border.all(color: ReverTheme.divider),
            boxShadow: ReverTheme.cardShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 10),
                Text(_content.body, style: ReverTheme.bodySmall),
                const SizedBox(height: 14),
                Container(height: 0.5, color: ReverTheme.divider),
                const SizedBox(height: 14),
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final c = _content;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: c.iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(c.icon, color: c.iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.title, style: ReverTheme.headingMedium.copyWith(fontSize: 14)),
              const SizedBox(height: 2),
              Text(c.subtitle, style: ReverTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    switch (_status) {
      case _CardStatus.loading:
        return const Center(
          child:
              CupertinoActivityIndicator(color: ReverTheme.accent, radius: 12),
        );

      case _CardStatus.confirmed:
      case _CardStatus.declined:
        return Row(
          children: [
            const Icon(CupertinoIcons.checkmark_circle_fill,
                color: ReverTheme.success, size: 16),
            const SizedBox(width: 6),
            Text(
              _status == _CardStatus.confirmed
                  ? _content.confirmedText
                  : 'Got it, showing next option…',
              style: ReverTheme.bodySmall.copyWith(
                color: _status == _CardStatus.confirmed
                    ? ReverTheme.success
                    : ReverTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );

      case _CardStatus.idle:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Accept — filled blue
            GestureDetector(
              onTap: _handleAccept,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: ReverTheme.accent,
                  borderRadius: BorderRadius.circular(ReverTheme.radiusMedium),
                  boxShadow: ReverTheme.floatingShadow,
                ),
                child: Center(
                  child: Text(
                    _content.acceptLabel,
                    style: ReverTheme.bodySmall.copyWith(
                      color: CupertinoColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            // Decline — ghost
            if (_content.declineLabel != null) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _handleDecline,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: ReverTheme.cardBg,
                    borderRadius:
                        BorderRadius.circular(ReverTheme.radiusMedium),
                    border: Border.all(color: ReverTheme.divider),
                  ),
                  child: Center(
                    child: Text(
                      _content.declineLabel!,
                      style: ReverTheme.bodySmall.copyWith(
                        color: ReverTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
    }
  }
}

class _StepContent {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String body;
  final String acceptLabel;
  final String? declineLabel;
  final String confirmedText;

  const _StepContent({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.acceptLabel,
    required this.declineLabel,
    required this.confirmedText,
  });
}

enum _CardStatus { idle, loading, confirmed, declined }
