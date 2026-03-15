import 'package:flutter/cupertino.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shimmer/shimmer.dart';

import '../models/chat_message.dart';
import '../theme/rever_theme.dart';
import 'product_offer_card.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const ChatBubble({super.key, required this.message});

  bool get _isUser => message.role == MessageRole.user;

  @override
  Widget build(BuildContext context) {
    if (message.isLoading) return _TypingIndicator();
    // Offer card — full-width bot widget, not a regular bubble
    if (message.offer != null) {
      return ProductOfferCard(product: message.offer!);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment:
            _isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!_isUser) _AvatarDot(),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 300),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _isUser ? ReverTheme.bubbleUser : ReverTheme.bubbleBot,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(ReverTheme.radiusMedium),
                  topRight: const Radius.circular(ReverTheme.radiusMedium),
                  bottomLeft:
                      Radius.circular(_isUser ? ReverTheme.radiusMedium : 4),
                  bottomRight:
                      Radius.circular(_isUser ? 4 : ReverTheme.radiusMedium),
                ),
                boxShadow: _isUser ? ReverTheme.floatingShadow : null,
              ),
              child: _isUser
                  ? Text(
                      message.content,
                      style: ReverTheme.bodyRegular
                          .copyWith(color: CupertinoColors.white),
                    )
                  : MarkdownBody(
                      data: message.content,
                      styleSheet: MarkdownStyleSheet(
                        p: ReverTheme.bodyRegular,
                        strong: ReverTheme.bodyRegular
                            .copyWith(fontWeight: FontWeight.w600),
                        em: ReverTheme.bodyRegular.copyWith(
                          color: ReverTheme.accent,
                          fontStyle: FontStyle.italic,
                        ),
                        code: ReverTheme.bodySmall.copyWith(
                          fontFamily: 'monospace',
                          backgroundColor: ReverTheme.surface,
                          color: ReverTheme.accent,
                        ),
                        blockquoteDecoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                                color: ReverTheme.accent, width: 3),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 8),
          if (_isUser)
            _TimestampText(message.timestamp)
          else
            const SizedBox(width: 24),
        ],
      ),
    );
  }
}

class _AvatarDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ReverTheme.accent, Color(0xFF9B96FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(ReverTheme.radiusFull),
        boxShadow: ReverTheme.glowShadow,
      ),
      child: Center(
        child: Text('R',
            style: ReverTheme.caption.copyWith(
              color: CupertinoColors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            )),
      ),
    );
  }
}

class _TimestampText extends StatelessWidget {
  final DateTime timestamp;
  const _TimestampText(this.timestamp);

  @override
  Widget build(BuildContext context) {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    return Text('$h:$m', style: ReverTheme.caption);
  }
}

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          _AvatarDot(),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: ReverTheme.bubbleBot,
              borderRadius: BorderRadius.circular(ReverTheme.radiusMedium),
            ),
            child: Row(
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (_, __) {
                    final progress =
                        (_controller.value - i * 0.15).clamp(0.0, 1.0);
                    final opacity = (0.25 +
                            0.75 *
                                (progress < 0.5
                                    ? progress * 2
                                    : 2 - progress * 2))
                        .clamp(0.25, 1.0);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.5),
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: ReverTheme.accent,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton loader ──────────────────────────────────────────────────────────
class ChatSkeleton extends StatelessWidget {
  const ChatSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: ReverTheme.cardBg,
      highlightColor: ReverTheme.cardBgRaised,
      child: Column(
        children: List.generate(
          4,
          (i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment:
                  i.isEven ? MainAxisAlignment.start : MainAxisAlignment.end,
              children: [
                Container(
                  width: i.isEven ? 200 : 140,
                  height: 40,
                  decoration: BoxDecoration(
                    color: ReverTheme.cardBgRaised,
                    borderRadius:
                        BorderRadius.circular(ReverTheme.radiusMedium),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
