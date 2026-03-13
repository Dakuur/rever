import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/app_config.dart';
import '../models/chat_message.dart';
import 'shopify_service.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._();
  factory GeminiService() => _instance;
  GeminiService._();

  late final GenerativeModel _model;
  bool _initialized = false;

  void _ensureInitialized() {
    if (!_initialized) {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: AppConfig.geminiApiKey,
        systemInstruction: Content.system(_systemPromptPrePurchase),
      );
      _initialized = true;
    }
  }

  // ── System Prompts ───────────────────────────────────────────────────────
  static const String _systemPromptPrePurchase = '''
You are REVER's friendly shopping assistant embedded on a Shopify store.
Your goal is to help customers find products, check availability, compare options and answer pre-purchase questions.

Guidelines:
- Be concise, warm and helpful.
- When the user asks about a specific product, price or stock, always include the relevant product details provided in the context.
- If you don't know something, say so honestly rather than guessing.
- Format prices with the currency symbol.
- Keep responses to 2-3 short paragraphs max.
- Respond in the same language as the user.
''';

  static const String _systemPromptPostPurchase = '''
You are REVER's returns assistant. Your goal is to help customers with order returns and exchanges.

IMPORTANT FLOW:
1. First ask for the customer's email and order number if not provided.
2. Acknowledge the return reason with empathy.
3. ALWAYS offer these alternatives BEFORE mentioning refund:
   a) Size/colour exchange (free, same item in different variant)
   b) Gift card with a BONUS of +5€ extra value
4. Only offer a full refund if the customer explicitly declines both alternatives.
5. Confirm the chosen resolution and inform that the team will follow up by email.

Rules:
- Never skip directly to refund. Always offer exchange and gift card first.
- Be empathetic and professional.
- Respond in the same language as the user.
''';

  // ── Pre-purchase chat ────────────────────────────────────────────────────
  Future<String> sendPrePurchaseMessage({
    required String userMessage,
    required List<ChatMessage> history,
  }) async {
    _ensureInitialized();

    // Fetch Shopify product context for this query
    String productContext = '';
    try {
      productContext =
          await ShopifyService().buildProductContext(userMessage);
    } catch (_) {
      // Storefront API unavailable – continue without context
    }

    final contextualMessage = productContext.isNotEmpty
        ? '$userMessage\n\n[Store context]\n$productContext'
        : userMessage;

    final chatHistory = history
        .where((m) => !m.isLoading)
        .map((m) => m.role == MessageRole.user
            ? Content.text(m.content)
            : Content.model([TextPart(m.content)]))
        .toList();

    final chat = _model.startChat(history: chatHistory);
    final response = await chat.sendMessage(Content.text(contextualMessage));
    return response.text ?? 'Sorry, I could not generate a response.';
  }

  // ── Post-purchase / returns chat ─────────────────────────────────────────
  Future<String> sendReturnMessage({
    required String userMessage,
    required List<ChatMessage> history,
  }) async {
    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: AppConfig.geminiApiKey,
      systemInstruction: Content.system(_systemPromptPostPurchase),
    );

    final chatHistory = history
        .where((m) => !m.isLoading)
        .map((m) => m.role == MessageRole.user
            ? Content.text(m.content)
            : Content.model([TextPart(m.content)]))
        .toList();

    final chat = model.startChat(history: chatHistory);
    final response = await chat.sendMessage(Content.text(userMessage));
    return response.text ?? 'Sorry, I could not generate a response.';
  }
}
