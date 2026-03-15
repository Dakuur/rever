import 'package:flutter/cupertino.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_message.dart';
import '../models/return_request.dart';
import '../services/firebase_service.dart';
import '../services/gemini_service.dart';
import '../services/shopify_service.dart';
import '../theme/rever_theme.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/return_option_card.dart';

enum ReturnStep { collectInfo, offerAlternatives, confirm, done }

class ReturnFlowScreen extends StatefulWidget {
  const ReturnFlowScreen({super.key});

  @override
  State<ReturnFlowScreen> createState() => _ReturnFlowScreenState();
}

class _ReturnFlowScreenState extends State<ReturnFlowScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _firebaseSvc = FirebaseService();
  final _geminiSvc = GeminiService();
  final _uuid = const Uuid();

  final List<ChatMessage> _messages = [];
  bool _isWaiting = false;
  ReturnStep _step = ReturnStep.collectInfo;
  String? _conversationId;
  String? _customerEmail;
  String? _orderId;
  ReturnOption? _selectedOption;

  // Stores gathered info for Firestore record
  String _productDescription = '';
  String _returnReason = '';

  @override
  void initState() {
    super.initState();
    _initConversation();
  }

  Future<void> _initConversation() async {
    try {
      _conversationId =
          await _firebaseSvc.createConversation('postPurchase');
    } catch (_) {
      _conversationId = _uuid.v4();
    }
    _addBotMessage(
      "Hello! I'm REVER's returns assistant. 📦\n\n"
      "To get started, please share:\n"
      "- Your **order email address**\n"
      "- Your **order number** (e.g. #1234)",
    );
  }

  void _addBotMessage(String content) {
    final msg = ChatMessage(
      id: _uuid.v4(),
      role: MessageRole.assistant,
      content: content,
      timestamp: DateTime.now(),
    );
    setState(() => _messages.add(msg));
    _saveMessage(msg);
    _scrollToBottom();
  }

  void _addUserMessage(String content) {
    final msg = ChatMessage(
      id: _uuid.v4(),
      role: MessageRole.user,
      content: content,
      timestamp: DateTime.now(),
    );
    setState(() => _messages.add(msg));
    _saveMessage(msg);
    _scrollToBottom();
  }

  Future<void> _saveMessage(ChatMessage msg) async {
    if (_conversationId == null) return;
    try {
      await _firebaseSvc.addMessage(_conversationId!, msg);
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isWaiting) return;

    _textController.clear();
    _addUserMessage(text);

    // --- State machine ---
    switch (_step) {
      case ReturnStep.collectInfo:
        await _handleCollectInfo(text);
        break;
      case ReturnStep.offerAlternatives:
        // User is chatting freely; use Gemini
        await _handleGeminiReturn(text);
        break;
      default:
        await _handleGeminiReturn(text);
    }
  }

  Future<void> _handleCollectInfo(String text) async {
    // Simple email/order extraction (Gemini does the heavy lifting)
    final emailRegex = RegExp(r'[\w\.-]+@[\w\.-]+\.\w+');
    final orderRegex = RegExp(r'#?\d{3,}');

    final emailMatch = emailRegex.firstMatch(text);
    final orderMatch = orderRegex.firstMatch(text);

    if (emailMatch != null) _customerEmail = emailMatch.group(0);
    if (orderMatch != null) {
      _orderId = orderMatch.group(0)?.replaceFirst('#', '');
    }

    if (_customerEmail != null && _orderId != null) {
      setState(() => _step = ReturnStep.offerAlternatives);
      _addBotMessage(
        "Thank you! I found your order **#$_orderId**. 👍\n\n"
        "Could you tell me:\n"
        "1. Which item(s) you'd like to return?\n"
        "2. The reason for the return?",
      );
    } else {
      await _handleGeminiReturn(text);
    }
  }

  Future<void> _handleGeminiReturn(String text) async {
    setState(() {
      _isWaiting = true;
      _messages.add(ChatMessage.loading());
    });
    _scrollToBottom();

    try {
      // Extract product/reason if not set
      if (_productDescription.isEmpty &&
          text.length > 10 &&
          _step == ReturnStep.offerAlternatives) {
        _productDescription = text.split(' ').take(6).join(' ');
      }

      String catalogContext = '';
      try {
        if (_productDescription.isNotEmpty) {
          catalogContext = await ShopifyService().buildProductContext(_productDescription);
        } else {
          catalogContext = await ShopifyService().getAllProducts().then(
            (products) {
              if (products.isEmpty) return '';
              final buf = StringBuffer('Available products:\n');
              for (final p in products) {
                buf.writeln('- ${p.title} | ${p.formattedPrice} | In stock: ${p.availableForSale} | Variants: ${p.variants.join(', ')}');
              }
              return buf.toString();
            },
          );
        }
      } catch (e) {
        print('[ReturnFlowScreen] ⚠️ Could not fetch product catalog: $e');
      }

      final response = await _geminiSvc.sendReturnMessage(
        userMessage: text,
        history: _messages.where((m) => !m.isLoading).toList(),
        productCatalogContext: catalogContext,
      );

      setState(() {
        _messages.removeWhere((m) => m.isLoading);
        _isWaiting = false;
      });

      // Check if Gemini offered alternatives → show option cards
      final lower = response.toLowerCase();
      if (_step == ReturnStep.offerAlternatives &&
          (lower.contains('exchange') ||
              lower.contains('gift card') ||
              lower.contains('refund'))) {
        _addBotMessage(response);
        _showAlternativesPanel();
      } else {
        _addBotMessage(response);
      }
    } catch (_) {
      setState(() {
        _messages.removeWhere((m) => m.isLoading);
        _isWaiting = false;
      });
      _addBotMessage('Sorry, there was an error. Please try again.');
    }
  }

  void _showAlternativesPanel() {
    setState(() => _step = ReturnStep.offerAlternatives);
  }

  Future<void> _selectOption(ReturnOption option) async {
    setState(() => _selectedOption = option);

    final labels = {
      ReturnOption.sizeExchange: 'a **size/colour exchange**',
      ReturnOption.giftCard: 'a **gift card with +€5 bonus**',
      ReturnOption.refund: 'a **full refund**',
    };

    _addUserMessage('I would like ${labels[option]}');

    // Save to Firestore
    final resolution = {
      ReturnOption.sizeExchange: ReturnResolution.sizeExchange,
      ReturnOption.giftCard: ReturnResolution.giftCard,
      ReturnOption.refund: ReturnResolution.refund,
    }[option]!;

    final req = ReturnRequest(
      id: _uuid.v4(),
      customerEmail: _customerEmail ?? 'unknown',
      orderId: _orderId ?? 'unknown',
      productDescription: _productDescription,
      reason: _returnReason,
      resolution: resolution,
      createdAt: DateTime.now(),
      userId: _firebaseSvc.currentUser?.uid,
    );

    try {
      await _firebaseSvc.saveReturnRequest(req);
    } catch (_) {}

    setState(() => _step = ReturnStep.confirm);

    final confirmMsg = {
      ReturnOption.sizeExchange:
          'Perfect! ✅ Your exchange request has been registered. '
              'Our team will contact you at **$_customerEmail** within 24h to confirm the new size/colour.',
      ReturnOption.giftCard:
          'Great choice! 🎁 Your gift card (+ €5 bonus) will be sent to **$_customerEmail** within 24h. '
              'Reference: **RTN-${req.id.substring(0, 8).toUpperCase()}**',
      ReturnOption.refund:
          'Understood. 💳 Your refund request has been submitted. '
              'You will receive a confirmation at **$_customerEmail** and the refund will appear '
              'in 3–5 business days. Reference: **RTN-${req.id.substring(0, 8).toUpperCase()}**',
    }[option]!;

    _addBotMessage(confirmMsg);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: ReverTheme.surface,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: ReverTheme.cardBg.withValues(alpha: 0.92),
        border: const Border(
            bottom: BorderSide(color: ReverTheme.divider, width: 0.5)),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: const Icon(CupertinoIcons.xmark,
              color: ReverTheme.textSecondary, size: 20),
        ),
        middle: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: ReverTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(CupertinoIcons.arrow_uturn_left,
                    color: ReverTheme.error, size: 14),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Returns & Exchanges',
                style:
                    TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (_, i) => ChatBubble(message: _messages[i]),
              ),
            ),
            // ── Option cards (shown after Gemini offers alternatives) ──
            if (_step == ReturnStep.offerAlternatives &&
                _selectedOption == null)
              _AlternativesPanel(onSelected: _selectOption),
            // ── Input bar (hidden after confirmation) ──
            if (_step != ReturnStep.done)
              _ReturnInputBar(
                controller: _textController,
                isLoading: _isWaiting,
                onSend: _sendMessage,
                step: _step,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Alternatives Panel ───────────────────────────────────────────────────────
class _AlternativesPanel extends StatefulWidget {
  final void Function(ReturnOption) onSelected;
  const _AlternativesPanel({required this.onSelected});

  @override
  State<_AlternativesPanel> createState() => _AlternativesPanelState();
}

class _AlternativesPanelState extends State<_AlternativesPanel> {
  ReturnOption? _hovered;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      decoration: const BoxDecoration(
        color: ReverTheme.cardBg,
        border:
            Border(top: BorderSide(color: ReverTheme.divider, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choose your resolution:',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ReverTheme.textSecondary)),
          const SizedBox(height: 8),
          // Exchange and Gift Card first (incentive options)
          ...ReturnOption.values.map((opt) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ReturnOptionCard(
                  option: opt,
                  isSelected: _hovered == opt,
                  onSelected: () {
                    setState(() => _hovered = opt);
                    Future.delayed(
                      const Duration(milliseconds: 200),
                      () => widget.onSelected(opt),
                    );
                  },
                ),
              )),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ── Return Input Bar ─────────────────────────────────────────────────────────
class _ReturnInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;
  final ReturnStep step;

  const _ReturnInputBar({
    required this.controller,
    required this.isLoading,
    required this.onSend,
    required this.step,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = step == ReturnStep.collectInfo
        ? 'Email & order number…'
        : 'Describe the issue…';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(
        color: ReverTheme.cardBg,
        border: Border(top: BorderSide(color: ReverTheme.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: CupertinoTextField(
              controller: controller,
              placeholder: placeholder,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: ReverTheme.surface,
                borderRadius: BorderRadius.circular(ReverTheme.radiusFull),
                border: Border.all(color: ReverTheme.divider),
              ),
              style: ReverTheme.bodyRegular,
              maxLines: 3,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: isLoading ? null : onSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isLoading ? ReverTheme.textSecondary : ReverTheme.error,
                borderRadius: BorderRadius.circular(ReverTheme.radiusFull),
              ),
              child: isLoading
                  ? const CupertinoActivityIndicator(
                      color: CupertinoColors.white, radius: 10)
                  : const Icon(CupertinoIcons.arrow_up,
                      color: CupertinoColors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
