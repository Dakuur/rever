import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_message.dart';
import '../models/shopify_product.dart';
import '../services/cart_service.dart';
import '../services/chatbot_service.dart';
import '../services/session_service.dart';
import '../services/shopify_service.dart';
import '../theme/rever_theme.dart';
import '../widgets/chat_bubble.dart';
import 'return_flow_screen.dart';

class ChatScreen extends StatefulWidget {
  final ChatMode mode;
  const ChatScreen({super.key, this.mode = ChatMode.prePurchase});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _chatbotSvc = ChatbotService();
  final _sessionSvc = SessionService();
  final _uuid = const Uuid();

  String? _sessionId;
  final List<ChatMessage> _messages = [];
  bool _isLoadingHistory = true;
  bool _isWaitingForBot = false;
  late ChatMode _mode;
  late AnimationController _sendBtnAnim;

  @override
  void initState() {
    super.initState();
    _mode = widget.mode;
    _sendBtnAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    CartService().init(); // start listening for cart postMessage from Shopify parent
    _initSession();
  }

  // ── Session init + history rehidration ────────────────────────────────────

  Future<void> _initSession() async {
    final sessionId = await _sessionSvc.getOrCreateSessionId();
    final history = await _sessionSvc.loadRecentMessages(sessionId);

    if (!mounted) return;
    setState(() {
      _sessionId = sessionId;
      _isLoadingHistory = false;
      if (history.isEmpty) {
        // Fresh session — show welcome message without persisting it.
        _messages.add(_buildWelcomeMessage());
      } else {
        _messages.addAll(history);
        _scrollToBottom();
      }
    });
  }

  ChatMessage _buildWelcomeMessage() => ChatMessage(
        id: _uuid.v4(),
        role: MessageRole.assistant,
        content: _mode == ChatMode.prePurchase
            ? "Hi! 👋 I'm REVER, your shopping assistant. How can I help you today?\n\nYou can ask me about products, sizes, prices or availability."
            : "Hello! I'm here to help you with your return. 📦\n\nTo get started, please tell me your **order email address** and **order number**.",
        timestamp: DateTime.now(),
      );

  // ── Message helpers ───────────────────────────────────────────────────────

  void _addBotMessage(String content) {
    final msg = ChatMessage(
      id: _uuid.v4(),
      role: MessageRole.assistant,
      content: content,
      timestamp: DateTime.now(),
    );
    setState(() => _messages.add(msg));
    _persistMessage(msg);
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
    _persistMessage(msg);
    _scrollToBottom();
  }

  void _persistMessage(ChatMessage msg) {
    if (_sessionId == null) return;
    _sessionSvc.saveMessage(_sessionId!, msg);
  }

  // ── Offer / add-to-cart trigger detection ────────────────────────────────

  ShopifyProduct? _lastRecommendedProduct;
  String _lastOfferQuery = '';

  static const _offerTriggers = [
    // English
    'offer', 'offers', 'sale', 'sales', 'deal', 'deals',
    'discount', 'discounts', 'promotion', 'promo',
    'recommend', 'recommendation', 'suggest', 'suggestion',
    'cheap', 'cheapest', 'best price', 'expensive', 'most expensive',
    'show me', 'find me',
    // Spanish
    'recomienda', 'recomiendame', 'recomendación', 'recomendacion',
    'oferta', 'ofertas', 'descuento', 'descuentos',
    'promoción', 'promocion',
    'barato', 'baratos', 'más barato', 'mas barato', 'precio bajo',
    'caro', 'mas caro', 'más caro', 'el más caro', 'el mas caro',
    'sugerencia', 'sugiere', 'sugiéreme',
    'muéstrame', 'muestrame', 'encuéntrame', 'encuentrame',
    'dame el', 'dame algo', 'dame un', 'dame una',
    'qué tienes', 'que tienes', 'qué hay', 'que hay',
  ];

  static const _addToCartTriggers = [
    // English
    'add to cart', 'add it', 'buy it', 'i want it', 'i\'ll take it',
    // Spanish
    'añadir al carrito', 'añadelo', 'añádelo', 'añadir',
    'agregar al carrito', 'agrégalo', 'agregalo',
    'lo quiero', 'quiero comprarlo', 'quiero ese', 'quiero éste',
    'comprar', 'cómpralo', 'compralo',
  ];

  bool _isOfferTrigger(String text) {
    final lower = text.toLowerCase();
    return _offerTriggers.any((t) => lower.contains(t));
  }

  bool _isAddToCartTrigger(String text) {
    final lower = text.toLowerCase();
    return _addToCartTriggers.any((t) => lower.contains(t));
  }

  Future<void> _handleOfferTrigger(String userQuery) async {
    _lastOfferQuery = userQuery;
    setState(() {
      _isWaitingForBot = true;
      _messages.add(ChatMessage.loading());
    });
    _scrollToBottom();

    try {
      final product = await ShopifyService().fetchRecommendedProduct(userQuery);
      setState(() {
        _messages.removeWhere((m) => m.isLoading);
        _isWaitingForBot = false;
      });

      if (product == null || !product.availableForSale) {
        _addBotMessage(
            "Sorry, I couldn't find any products on sale right now. "
            "Feel free to ask me about any specific item!");
        return;
      }

      _lastRecommendedProduct = product;
      print('[ChatScreen] 💡 Offer card shown — product="${product.title}" variantId=${product.variantId}');

      _addBotMessage(product.isOnSale
          ? "I found a great deal for you! 🎉"
          : "Here's one of our top picks for you:");

      final offerMsg = ChatMessage(
        id: _uuid.v4(),
        role: MessageRole.assistant,
        content: '',
        timestamp: DateTime.now(),
        offer: product,
      );
      setState(() => _messages.add(offerMsg));
      _scrollToBottom();
    } catch (e) {
      print('[ChatScreen] ❌ fetchSaleProduct error: $e');
      setState(() {
        _messages.removeWhere((m) => m.isLoading);
        _isWaitingForBot = false;
      });
      _addBotMessage('Sorry, something went wrong. Please try again.');
    }
  }

  Future<void> _handleAddToCartTrigger() async {
    final product = _lastRecommendedProduct;
    if (product == null) {
      print('[ChatScreen] ℹ️ Add-to-cart trigger but no last product — showing offer card instead');
      await _handleOfferTrigger(_lastOfferQuery.isEmpty ? 'recommend' : _lastOfferQuery);
      return;
    }

    print('[ChatScreen] 🛒 Add-to-cart trigger — using last product "${product.title}" variantId=${product.variantId}');

    // Show the offer card for the last recommended product so the user confirms
    _addBotMessage('Here\'s the product I recommended — confirm to add it to your cart:');
    final offerMsg = ChatMessage(
      id: _uuid.v4(),
      role: MessageRole.assistant,
      content: '',
      timestamp: DateTime.now(),
      offer: product,
    );
    setState(() => _messages.add(offerMsg));
    _scrollToBottom();
  }

  // ── Send message ──────────────────────────────────────────────────────────

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isWaitingForBot) return;

    _textController.clear();
    _addUserMessage(text);

    // Add-to-cart trigger: skip AI, show offer card for last product
    if (_mode == ChatMode.prePurchase && _isAddToCartTrigger(text)) {
      print('[ChatScreen] 🛒 Add-to-cart trigger detected: "$text"');
      await _handleAddToCartTrigger();
      return;
    }

    // Offer trigger: skip AI, fetch recommended product directly (faster)
    if (_mode == ChatMode.prePurchase && _isOfferTrigger(text)) {
      print('[ChatScreen] 💡 Offer trigger detected: "$text"');
      await _handleOfferTrigger(text);
      return;
    }

    setState(() {
      _isWaitingForBot = true;
      _messages.add(ChatMessage.loading());
    });
    _scrollToBottom();

    try {
      final history = _messages.where((m) => !m.isLoading).toList();
      String response;
      if (_mode == ChatMode.prePurchase) {
        response = await _chatbotSvc.sendPrePurchaseMessage(
          userMessage: text,
          history: history,
          cartContext: CartService().buildCartContext(),
        );
      } else {
        response = await _chatbotSvc.sendReturnMessage(
          userMessage: text,
          history: history,
        );
      }
      setState(() {
        _messages.removeWhere((m) => m.isLoading);
        _isWaitingForBot = false;
      });
      _addBotMessage(response);
    } catch (e, stack) {
      print('[ChatScreen] ❌ Unhandled exception in _sendMessage: $e\n$stack');
      setState(() {
        _messages.removeWhere((m) => m.isLoading);
        _isWaitingForBot = false;
      });
      _addBotMessage('Sorry, something went wrong. Please try again.');
    }
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

  // ── Reset chat ────────────────────────────────────────────────────────────

  Future<void> _resetChat() async {
    final confirmed = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (ctx) => Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 32),
        decoration: BoxDecoration(
          color: ReverTheme.cardBg,
          borderRadius: BorderRadius.circular(ReverTheme.radiusLarge),
          boxShadow: ReverTheme.cardShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Start a new chat?', style: ReverTheme.headingMedium),
                  const SizedBox(height: 4),
                  Text(
                    'This will clear the current conversation.',
                    style: ReverTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Container(height: 0.5, color: ReverTheme.divider),
            // ── Actions ──
            Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text('Cancel',
                        style: ReverTheme.bodyRegular.copyWith(
                          color: ReverTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        )),
                  ),
                ),
                Container(width: 0.5, height: 52, color: ReverTheme.divider),
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text('Clear',
                        style: ReverTheme.bodyRegular.copyWith(
                          color: ReverTheme.error,
                          fontWeight: FontWeight.w700,
                        )),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _messages.clear();
      _isLoadingHistory = true;
    });

    final newSessionId = await _sessionSvc.resetSession();
    if (!mounted) return;
    setState(() {
      _sessionId = newSessionId;
      _isLoadingHistory = false;
      _messages.add(_buildWelcomeMessage());
    });
  }

  bool get _hasUserMessages =>
      _messages.any((m) => m.role == MessageRole.user);

  void _switchToReturnMode() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => const ReturnFlowScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _sendBtnAnim.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: ReverTheme.surface,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: ReverTheme.cardBg.withValues(alpha: 0.92),
        border: const Border(
            bottom: BorderSide(color: ReverTheme.divider, width: 0.5)),
        middle: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [ReverTheme.accent, Color(0xFF9B96FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(7),
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
            ),
            const SizedBox(width: 8),
            Text('REVER', style: ReverTheme.headingMedium),
          ],
        ),
        leading: _hasUserMessages
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _resetChat,
                child: const Icon(
                  CupertinoIcons.refresh,
                  color: ReverTheme.textSecondary,
                  size: 18,
                ),
              )
            : null,
        trailing: _mode == ChatMode.prePurchase
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _switchToReturnMode,
                child: Text('Returns',
                    style: ReverTheme.bodySmall.copyWith(
                      color: ReverTheme.accent,
                      fontWeight: FontWeight.w600,
                    )),
              )
            : null,
      ),
      child: SafeArea(
        child: Column(
          children: [
            if (_mode == ChatMode.prePurchase)
              _ModeSwitcherBanner(onReturnTap: _switchToReturnMode),
            Expanded(child: _buildBody()),
            if (!_isLoadingHistory)
              _InputBar(
                controller: _textController,
                isLoading: _isWaitingForBot,
                onSend: _sendMessage,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoadingHistory) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CupertinoActivityIndicator(
                radius: 12, color: ReverTheme.accent),
            const SizedBox(height: 12),
            Text('Loading…', style: ReverTheme.bodySmall),
          ],
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (_, i) => ChatBubble(message: _messages[i]),
    );
  }
}

// ── Mode Switcher Banner ──────────────────────────────────────────────────────

class _ModeSwitcherBanner extends StatelessWidget {
  final VoidCallback onReturnTap;
  const _ModeSwitcherBanner({required this.onReturnTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: ReverTheme.accentLight,
        borderRadius: BorderRadius.circular(ReverTheme.radiusMedium),
        border: Border.all(
            color: ReverTheme.accent.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.arrow_uturn_left,
              color: ReverTheme.accent, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Already purchased? Start a return or exchange.',
              style: ReverTheme.bodySmall
                  .copyWith(color: ReverTheme.textPrimary),
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            onPressed: onReturnTap,
            child: Text('Start →',
                style: ReverTheme.bodySmall.copyWith(
                  color: ReverTheme.accent,
                  fontWeight: FontWeight.w700,
                )),
          ),
        ],
      ),
    );
  }
}

// ── Input Bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.isLoading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: const BoxDecoration(
        color: ReverTheme.cardBg,
        border: Border(top: BorderSide(color: ReverTheme.divider, width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: CupertinoTextField(
              controller: controller,
              placeholder: 'Ask about products…',
              placeholderStyle: ReverTheme.bodyRegular
                  .copyWith(color: ReverTheme.textSecondary),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: ReverTheme.cardBgRaised,
                borderRadius: BorderRadius.circular(ReverTheme.radiusMedium),
                border: Border.all(color: ReverTheme.divider),
              ),
              style: ReverTheme.bodyRegular,
              maxLines: 4,
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
                color: isLoading ? ReverTheme.cardBgRaised : ReverTheme.accent,
                borderRadius: BorderRadius.circular(ReverTheme.radiusMedium),
                boxShadow: isLoading ? null : ReverTheme.floatingShadow,
              ),
              child: isLoading
                  ? const CupertinoActivityIndicator(
                      color: ReverTheme.accent, radius: 10)
                  : const Icon(CupertinoIcons.arrow_up,
                      color: CupertinoColors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
