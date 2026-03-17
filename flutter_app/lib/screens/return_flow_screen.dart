import 'package:flutter/cupertino.dart';
import 'package:uuid/uuid.dart';

import '../l10n/app_strings.dart';
import '../models/chat_message.dart';
import '../models/return_request.dart';
import '../services/chatbot_service.dart';
import '../services/firebase_service.dart';
import '../services/functions_service.dart';
import '../services/language_service.dart';
import '../services/order_service.dart';
import '../theme/rever_theme.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/incentive_step_card.dart';

// ── State machine ──────────────────────────────────────────────────────────

enum _FlowStep {
  collectInfo,   // waiting for email + order ID
  validating,    // calling OrderService
  collectReason, // order confirmed, waiting for return reason
  awaitingAI,    // generating empathetic AI response
  ladder,        // showing incentive cards
  done,          // flow complete
}

// ── Screen ─────────────────────────────────────────────────────────────────

class ReturnFlowScreen extends StatefulWidget {
  const ReturnFlowScreen({super.key});

  @override
  State<ReturnFlowScreen> createState() => _ReturnFlowScreenState();
}

class _ReturnFlowScreenState extends State<ReturnFlowScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _chatbotSvc = ChatbotService();
  final _firebaseSvc = FirebaseService();
  final _orderSvc = OrderService();
  final _functionsSvc = FunctionsService();
  final _uuid = const Uuid();

  final List<ChatMessage> _messages = [];
  _FlowStep _step = _FlowStep.collectInfo;
  LadderStep _ladderStep = LadderStep.exchange;
  bool _inputEnabled = true;

  // Collected data
  bool _orderVerified = false;
  String? _customerEmail;
  String? _rawOrderId;
  String? _productQuery;
  ValidatedOrder? _order;
  String _returnReason = '';
  String? _conversationId;

  AppStrings get _s => AppStrings.of(LanguageService().code);

  @override
  void initState() {
    super.initState();
    _initFlow();
  }

  // ── Init ───────────────────────────────────────────────────────────────────

  Future<void> _initFlow() async {
    try {
      _conversationId = await _firebaseSvc.createConversation('returns');
    } catch (_) {
      _conversationId = _uuid.v4();
    }
    _addBot(_s.returnInitMessage);
  }

  // ── Message helpers ────────────────────────────────────────────────────────

  void _addBot(String content) {
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

  void _addUser(String content) {
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

  void _showLoading() {
    setState(() => _messages.add(ChatMessage.loading()));
    _scrollToBottom();
  }

  void _removeLoading() {
    setState(() => _messages.removeWhere((m) => m.isLoading));
  }

  // ── Send handler ───────────────────────────────────────────────────────────

  Future<void> _onSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty || !_inputEnabled) return;
    _textController.clear();
    LanguageService().refineFromText(text);
    _addUser(text);

    switch (_step) {
      case _FlowStep.collectInfo:
        await _handleCollectInfo(text);
        break;
      case _FlowStep.collectReason:
        await _handleCollectReason(text);
        break;
      default:
        break;
    }
  }

  // ── Step: collect email + order ID ─────────────────────────────────────────

  Future<void> _handleCollectInfo(String text) async {
    print('[CollectInfo] input: "$text"');
    print('[CollectInfo] state before: email=$_customerEmail orderId=$_rawOrderId product=$_productQuery');

    final emailRegex = RegExp(r'[\w.+-]+@[\w.-]+\.\w+');
    final orderRegex = RegExp(r'#?\d{2,}');

    // If we already have email+order, this reply is the product description
    if (_customerEmail != null && _rawOrderId != null && _productQuery == null) {
      _productQuery = text.trim();
      print('[CollectInfo] product set from follow-up reply: "$_productQuery"');
    } else {
      final emailMatch = emailRegex.firstMatch(text);
      final orderMatch = orderRegex.firstMatch(text);

      print('[CollectInfo] email regex match: ${emailMatch?.group(0)}');
      print('[CollectInfo] order regex match: ${orderMatch?.group(0)}');

      if (emailMatch != null) _customerEmail = emailMatch.group(0);
      if (orderMatch != null) {
        _rawOrderId = orderMatch.group(0)?.replaceFirst('#', '');
      }

      // Extract product: text minus email and order number
      if (_customerEmail != null && _rawOrderId != null) {
        final remaining = text
            .replaceAll(emailRegex, '')
            .replaceAll(orderRegex, '')
            .replaceAll(RegExp(r'[#,]'), '')
            .replaceAll(RegExp(
                r'\b(order|pedido|número|numero|codigo|código|email|correo|quiero|devolver|return|producto|product|article|artikel|articulo|artículo|my|mi|the|el|la|y|and|avec|avec|con|de|du|und|met|het|com|meu|minha|il|lo|un|una|une|ein|eine)\b',
                caseSensitive: false), '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        print('[CollectInfo] remaining after stripping email+order+keywords: "$remaining"');
        if (remaining.length > 2) _productQuery = remaining;
      }
    }

    print('[CollectInfo] state after parse: email=$_customerEmail orderId=$_rawOrderId product=$_productQuery');

    if (_customerEmail == null || _rawOrderId == null) {
      print('[CollectInfo] missing email or orderId, asking again');
      _addBot(_s.missingInfoError);
      return;
    }

    if (_productQuery == null) {
      print('[CollectInfo] missing product, asking for it');
      _addBot(_s.productQueryPrompt);
      return;
    }

    // Verify order number via Cloud Function (blocking: only prime numbers pass).
    if (!_orderVerified) {
      print('[CollectInfo] calling CF verifyOrderNumber for orderId=$_rawOrderId');
      setState(() {
        _step = _FlowStep.validating;
        _inputEnabled = false;
      });
      _showLoading();

      bool isValid = false;
      try {
        isValid = await _functionsSvc.verifyOrderNumber(_rawOrderId!);
        print('[CollectInfo] CF result: orderId=$_rawOrderId isValid=$isValid (prime check)');
      } catch (e) {
        print('[CollectInfo] CF error: $e — treating as invalid');
      }

      _removeLoading();

      if (!isValid) {
        print('[CollectInfo] order number $_rawOrderId rejected (not prime), resetting');
        setState(() {
          _step = _FlowStep.collectInfo;
          _inputEnabled = true;
          _rawOrderId = null;
          _productQuery = null;
        });
        _addBot(_s.orderNumberInvalidError);
        return;
      }

      _orderVerified = true;
      print('[CollectInfo] order number $_rawOrderId accepted (prime), proceeding');
    }

    print('[CollectInfo] all fields collected, calling OrderService');
    setState(() {
      _step = _FlowStep.validating;
      _inputEnabled = false;
    });
    _showLoading();

    final order = await _orderSvc.validateOrder(
      orderId: _rawOrderId!,
      email: _customerEmail!,
      productQuery: _productQuery!,
    );

    _removeLoading();

    if (order == null) {
      print('[CollectInfo] OrderService returned null for product="$_productQuery"');
      final failedQuery = _productQuery;
      setState(() {
        _step = _FlowStep.collectInfo;
        _inputEnabled = true;
        _productQuery = null;
      });
      _addBot(_s.productNotFoundError(failedQuery ?? ''));
      return;
    }

    print('[CollectInfo] order validated: id=${order.orderId} product="${order.productTitle}" total=${order.formattedTotal}');
    _order = order;
    setState(() {
      _step = _FlowStep.collectReason;
      _inputEnabled = true;
    });

    _addBot(_s.orderFoundMessage(
      orderId: order.orderId,
      productTitle: order.productTitle,
      productVariant: order.productVariant,
      formattedTotal: order.formattedTotal,
    ));
  }

  // ── Step: collect return reason ────────────────────────────────────────────

  Future<void> _handleCollectReason(String text) async {
    _returnReason = text;
    setState(() {
      _step = _FlowStep.awaitingAI;
      _inputEnabled = false;
    });
    _showLoading();

    // AI generates one empathetic response, then we show the ladder
    final langName = _s.languageName;
    String aiResponse;
    try {
      aiResponse = await _chatbotSvc.sendReturnMessage(
        userMessage:
            '[Order already verified — do NOT ask for email or order number.] '
            'Respond in $langName. '
            'Customer: $_customerEmail | Order #${_order!.orderId} | '
            'Product: ${_order!.productTitle} (${_order!.productVariant}) | '
            'Price: ${_order!.formattedTotal}. '
            'Return reason: "$_returnReason". '
            'Write 1-2 empathetic sentences acknowledging their reason. '
            'Do NOT ask for any information and do NOT offer options yet.',
        history: [],
      );
    } catch (_) {
      aiResponse = _s.aiFallbackEmpathy;
    }

    _removeLoading();
    _addBot(aiResponse);

    await Future.delayed(const Duration(milliseconds: 500));
    _addBot(_s.ladderIntro);

    setState(() {
      _step = _FlowStep.ladder;
      _ladderStep = LadderStep.exchange;
    });
    _scrollToBottom();
  }

  // ── Ladder callbacks ───────────────────────────────────────────────────────

  void _onExchangeAccepted() => _resolveReturn(ReturnResolution.sizeExchange);

  void _onExchangeDeclined() {
    _addBot(_s.exchangeDeclinedMessage);
    setState(() => _ladderStep = LadderStep.giftCard);
    _scrollToBottom();
  }

  void _onGiftCardAccepted() => _resolveReturn(ReturnResolution.giftCard);

  void _onGiftCardDeclined() {
    _addBot(_s.giftCardDeclinedMessage);
    setState(() => _ladderStep = LadderStep.upsell);
    _scrollToBottom();
  }

  void _onUpsellAccepted() => _resolveReturn(ReturnResolution.upsell);

  void _onUpsellDeclined() {
    _addBot(_s.upsellDeclinedMessage);
    setState(() => _ladderStep = LadderStep.refund);
    _scrollToBottom();
  }

  void _onRefundAccepted() => _resolveReturn(ReturnResolution.refund);

  // ── Resolve & persist ──────────────────────────────────────────────────────

  Future<void> _resolveReturn(ReturnResolution resolution) async {
    setState(() {
      _step = _FlowStep.done;
      _inputEnabled = false;
    });

    // Save to Firestore
    final req = ReturnRequest(
      id: _uuid.v4(),
      customerEmail: _customerEmail ?? 'unknown',
      orderId: _rawOrderId ?? 'unknown',
      productDescription:
          '${_order?.productTitle ?? ''} ${_order?.productVariant ?? ''}'.trim(),
      reason: _returnReason,
      resolution: resolution,
      createdAt: DateTime.now(),
      userId: _firebaseSvc.currentUser?.uid,
    );

    try {
      await _firebaseSvc.saveReturnRequest(req);
      print('[ReturnFlow] Saved to Firestore: ${req.id} resolution=${resolution.name}');
    } catch (e) {
      print('[ReturnFlow] ERROR Firestore save failed: $e');
    }

    final confirmationMsg = _buildConfirmation(resolution, req.id);
    _addBot(confirmationMsg);
    _scrollToBottom();
  }

  String _buildConfirmation(ReturnResolution resolution, String refId) {
    final shortRef = 'RTN-${refId.substring(0, 8).toUpperCase()}';
    final email = _customerEmail ?? '';
    switch (resolution) {
      case ReturnResolution.sizeExchange:
        return _s.confirmationExchange(email, shortRef);
      case ReturnResolution.giftCard:
        return _s.confirmationGiftCard(
            _order?.formattedGiftCard ?? '', email, shortRef);
      case ReturnResolution.upsell:
        return _s.confirmationUpsell(email, shortRef);
      case ReturnResolution.refund:
        return _s.confirmationRefund(_order?.formattedTotal ?? '', shortRef);
      default:
        return '${_s.confirmationDefault} Reference: **$shortRef**';
    }
  }

  // ── Scroll ─────────────────────────────────────────────────────────────────

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
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

  // ── Build ──────────────────────────────────────────────────────────────────

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
              color: ReverTheme.textSecondary, size: 18),
        ),
        middle: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Center(
                child: Icon(CupertinoIcons.arrow_uturn_left,
                    color: ReverTheme.error, size: 13),
              ),
            ),
            const SizedBox(width: 8),
            Text(_s.returnNavTitle, style: ReverTheme.headingMedium),
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
                itemCount: _messages.length + (_showLadderCard ? 1 : 0),
                itemBuilder: (_, i) {
                  if (i < _messages.length) {
                    return ChatBubble(message: _messages[i]);
                  }
                  return _buildLadderCard();
                },
              ),
            ),
            if (_step != _FlowStep.done && _step != _FlowStep.ladder)
              _ReturnInputBar(
                controller: _textController,
                enabled: _inputEnabled,
                onSend: _onSend,
                placeholder: _step == _FlowStep.collectInfo
                    ? (_customerEmail != null && _rawOrderId != null
                        ? _s.returnPlaceholderProduct
                        : _s.returnPlaceholderInfo)
                    : _s.returnPlaceholderReason,
              ),
          ],
        ),
      ),
    );
  }

  bool get _showLadderCard => _step == _FlowStep.ladder;

  Widget _buildLadderCard() {
    final order = _order!;
    switch (_ladderStep) {
      case LadderStep.exchange:
        return IncentiveStepCard(
          key: const ValueKey('exchange'),
          step: LadderStep.exchange,
          order: order,
          onAccepted: _onExchangeAccepted,
          onDeclined: _onExchangeDeclined,
        );
      case LadderStep.giftCard:
        return IncentiveStepCard(
          key: const ValueKey('giftCard'),
          step: LadderStep.giftCard,
          order: order,
          onAccepted: _onGiftCardAccepted,
          onDeclined: _onGiftCardDeclined,
        );
      case LadderStep.upsell:
        return IncentiveStepCard(
          key: const ValueKey('upsell'),
          step: LadderStep.upsell,
          order: order,
          onAccepted: _onUpsellAccepted,
          onDeclined: _onUpsellDeclined,
        );
      case LadderStep.refund:
        return IncentiveStepCard(
          key: const ValueKey('refund'),
          step: LadderStep.refund,
          order: order,
          onAccepted: _onRefundAccepted,
        );
    }
  }
}

// ── Input Bar ──────────────────────────────────────────────────────────────

class _ReturnInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;
  final String placeholder;

  const _ReturnInputBar({
    required this.controller,
    required this.enabled,
    required this.onSend,
    required this.placeholder,
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
              placeholder: placeholder,
              placeholderStyle: ReverTheme.bodyRegular
                  .copyWith(color: ReverTheme.textSecondary),
              enabled: enabled,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: enabled
                    ? ReverTheme.cardBgRaised
                    : ReverTheme.cardBgRaised.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(ReverTheme.radiusMedium),
                border: Border.all(color: ReverTheme.divider),
              ),
              style: ReverTheme.bodyRegular,
              maxLines: 3,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: enabled ? (_) => onSend() : null,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: enabled ? onSend : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: enabled ? ReverTheme.error : ReverTheme.cardBgRaised,
                borderRadius: BorderRadius.circular(ReverTheme.radiusMedium),
              ),
              child: Icon(
                CupertinoIcons.arrow_up,
                color: enabled
                    ? CupertinoColors.white
                    : ReverTheme.textSecondary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
