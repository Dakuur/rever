import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_message.dart';
import '../services/cart_service.dart';
import '../services/gemini_service.dart';
import '../services/session_service.dart';
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
  final _geminiSvc = GeminiService();
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

  // ── Send message ──────────────────────────────────────────────────────────

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isWaitingForBot) return;

    _textController.clear();
    _addUserMessage(text);
    setState(() {
      _isWaitingForBot = true;
      _messages.add(ChatMessage.loading());
    });
    _scrollToBottom();

    try {
      final history = _messages.where((m) => !m.isLoading).toList();
      String response;
      if (_mode == ChatMode.prePurchase) {
        response = await _geminiSvc.sendPrePurchaseMessage(
          userMessage: text,
          history: history,
          cartContext: CartService().buildCartContext(),
        );
      } else {
        response = await _geminiSvc.sendReturnMessage(
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
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Start a new chat?'),
        content: const Text(
            'This will clear the current conversation and start fresh.'),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
        ],
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
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [ReverTheme.accent, Color(0xFF9B96FF)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('R',
                    style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 8),
            const Text('REVER Assistant',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          ],
        ),
        leading: _hasUserMessages
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _resetChat,
                child: const Icon(
                  CupertinoIcons.refresh,
                  color: ReverTheme.textSecondary,
                  size: 20,
                ),
              )
            : null,
        trailing: _mode == ChatMode.prePurchase
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _switchToReturnMode,
                child: const Text('Returns',
                    style: TextStyle(
                        color: ReverTheme.accent,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
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
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoActivityIndicator(radius: 14),
            SizedBox(height: 12),
            Text('Loading conversation…',
                style: TextStyle(
                    fontSize: 14, color: ReverTheme.textSecondary)),
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
        border: Border.all(color: ReverTheme.accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.arrow_uturn_left,
              color: ReverTheme.accent, size: 16),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Already purchased? Start a return or exchange.',
              style: TextStyle(fontSize: 13, color: ReverTheme.textPrimary),
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            onPressed: onReturnTap,
            child: const Text('Start →',
                style: TextStyle(
                    color: ReverTheme.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
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
              placeholder: 'Ask about products…',
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: ReverTheme.surface,
                borderRadius:
                    BorderRadius.circular(ReverTheme.radiusFull),
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
                color: isLoading
                    ? ReverTheme.textSecondary
                    : ReverTheme.accent,
                borderRadius:
                    BorderRadius.circular(ReverTheme.radiusFull),
                boxShadow: isLoading ? null : ReverTheme.floatingShadow,
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
