import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/chat_message.dart';
import 'shopify_service.dart';

// Groq API — OpenAI-compatible REST endpoint.
// Model: llama-3.3-70b-versatile
const _groqEndpoint = 'https://api.groq.com/openai/v1/chat/completions';
const _groqModel = 'llama-3.3-70b-versatile';

class ChatbotService {
  static final ChatbotService _instance = ChatbotService._();
  factory ChatbotService() => _instance;
  ChatbotService._();

  // ── System Prompts ───────────────────────────────────────────────────────

  static const String _systemPromptPrePurchase = '''
You are REVER's friendly shopping assistant embedded on a Shopify store.
Your goal is to help customers find the right product, improve conversion, and reduce returns before they happen.

Guidelines:
- Be concise, warm and helpful. Keep responses to 2-3 short paragraphs max.
- Answer questions about products, pricing, availability, and variants using the store context provided.
- Guide shoppers to the right product based on their needs or use case (e.g. "I need a gift under €50").
- PROACTIVELY surface details that prevent post-purchase issues: sizing guides, compatibility info, material descriptions, and estimated shipping times.
- When a product might NOT be the best fit for the customer's stated need, say so honestly and suggest a better alternative from the catalog.
- If the customer has items in their cart (provided in context), reference them when relevant — e.g. for compatibility, complementary products, or upsells.
- Format prices with the currency symbol.
- Respond in the same language as the user.
''';

  static const String _systemPromptPostPurchase = '''
You are REVER's returns and exchanges assistant. Your goal is to minimise refunds by offering better alternatives.

RETURN FLOW:
1. Collect the customer's email and order number if not already provided.
2. Ask which item they want to return and why (return reason is important).
3. Acknowledge the reason with empathy.
4. ALWAYS offer alternatives BEFORE mentioning a refund, in this order:
   a) Exchange: different size, colour, or variant of the same product (free, instant).
   b) Gift card: offer €5 MORE than the refund value (e.g. "€55 gift card instead of a €50 refund").
   c) Different product: if the catalog context includes products that better fit their needs, suggest one specifically.
5. Only present a full refund AFTER the customer has explicitly declined all alternatives.
6. Once the customer chooses, confirm the resolution and let them know the team will follow up by email within 24h.

Rules:
- Never skip directly to refund. Always offer exchange and gift card first.
- Use the product catalog context (if provided) to suggest specific alternative products.
- Be empathetic, professional, and concise.
- Respond in the same language as the user.
''';

  // ── Core HTTP call ───────────────────────────────────────────────────────

  Future<String> _callGroq({
    required String systemPrompt,
    required String userMessage,
    required List<ChatMessage> history,
  }) async {
    final apiKey = AppConfig.groqApiKey;
    if (apiKey.isEmpty) {
      print('[Chatbot] ❌ GROQ_API_KEY is empty – pass --dart-define=GROQ_API_KEY=... at build time');
      return 'Configuration error: API key not set. Please contact support.';
    }

    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': systemPrompt},
    ];

    for (final msg in history.where((m) => !m.isLoading)) {
      messages.add({
        'role': msg.role == MessageRole.user ? 'user' : 'assistant',
        'content': msg.content,
      });
    }

    final preview = userMessage.substring(0, userMessage.length.clamp(0, 80));
    print('[Chatbot] ── Request ──────────────────────────────────────');
    print('[Chatbot]   model   : $_groqModel');
    print('[Chatbot]   messages: ${messages.length} (incl. system)');
    print('[Chatbot]   last msg: "$preview${userMessage.length > 80 ? "…" : ""}"');

    try {
      final response = await http.post(
        Uri.parse(_groqEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': _groqModel,
          'messages': messages,
          'temperature': 0.7,
          'max_completion_tokens': 1024,
          'top_p': 1,
          'stream': false,
        }),
      );

      print('[Chatbot] ── Response ─────────────────────────────────────');
      print('[Chatbot]   HTTP status : ${response.statusCode}');

      if (response.statusCode != 200) {
        final errPreview = response.body.substring(0, response.body.length.clamp(0, 400));
        print('[Chatbot]   ❌ Error body: $errPreview');
        return 'Error ${response.statusCode} from AI service. Please try again.';
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = json['choices'] as List<dynamic>? ?? [];
      if (choices.isEmpty) {
        print('[Chatbot]   ⚠️ Empty choices array. Full body: ${response.body}');
        return 'I received an empty response. Please try again.';
      }

      final finishReason = choices.first['finish_reason'] as String? ?? 'unknown';
      final content = choices.first['message']?['content'] as String? ?? '';
      final usage = json['usage'] as Map<String, dynamic>?;

      print('[Chatbot]   finish_reason     : $finishReason');
      print('[Chatbot]   reply length      : ${content.length} chars');
      if (usage != null) {
        print('[Chatbot]   tokens in/out/total: '
            '${usage['prompt_tokens']}/${usage['completion_tokens']}/${usage['total_tokens']}');
      }

      if (content.trim().isEmpty) {
        print('[Chatbot]   ⚠️ Content is empty despite finish_reason=$finishReason');
        return 'I received an empty response. Please try again.';
      }

      print('[Chatbot] ✅ Reply ready');
      return content;
    } catch (e, stack) {
      print('[Chatbot] ❌ Exception: $e');
      print('[Chatbot]   $stack');
      return 'Connection error: ${e.toString()}. Please try again.';
    }
  }

  // ── Product identification (for returns flow) ────────────────────────────

  /// Matches a user's free-text product description against a list of titles.
  /// Returns the 1-based index of the best match, or 0 if nothing matches.
  Future<int> identifyProduct(String userDescription, List<String> productTitles) async {
    if (productTitles.isEmpty) return 0;
    final numbered = productTitles.asMap().entries
        .map((e) => '${e.key + 1}. ${e.value}')
        .join('\n');
    print('[Chatbot] 🔍 identifyProduct — "$userDescription" vs ${productTitles.length} products');
    try {
      // Pass the prompt as a history entry so _callGroq includes it in the API call
      final reply = await _callGroq(
        systemPrompt:
            'You are a product matching assistant. '
            'Reply with ONLY a single number — the line number of the product that best matches '
            'the customer\'s description. Reply "0" if nothing matches well enough.',
        userMessage: '', // unused; content is in history below
        history: [
          ChatMessage(
            id: 'identify_tmp',
            role: MessageRole.user,
            content: 'Customer described: "$userDescription"\n\nCatalog:\n$numbered',
            timestamp: DateTime.now(),
          ),
        ],
      );
      // Extract the first standalone number from the reply (handles verbose responses)
      final numMatch = RegExp(r'\b(\d+)\b').firstMatch(reply.trim());
      final idx = numMatch != null ? (int.tryParse(numMatch.group(1)!) ?? 0) : 0;
      final matched = (idx > 0 && idx <= productTitles.length) ? productTitles[idx - 1] : 'no match';
      print('[Chatbot] 🔍 identifyProduct → idx=$idx ("$matched") | raw reply: "${reply.trim()}"');
      return idx;
    } catch (e) {
      print('[Chatbot] ❌ identifyProduct error: $e');
      return 0;
    }
  }

  // ── Pre-purchase chat ────────────────────────────────────────────────────

  Future<String> sendPrePurchaseMessage({
    required String userMessage,
    required List<ChatMessage> history,
    String cartContext = '',
  }) async {
    print('[Chatbot] ── Pre-purchase ──────────────────────────────────');
    print('[Chatbot]   cart context : ${cartContext.isEmpty ? "none" : "${cartContext.length} chars"}');

    String productContext = '';
    try {
      productContext = await ShopifyService().buildProductContext(userMessage);
    } catch (e) {
      print('[Chatbot]   ⚠️ Shopify product context failed: $e');
    }
    print('[Chatbot]   product context: ${productContext.isEmpty ? "none" : "${productContext.length} chars"}');

    final contextParts = <String>[];
    if (productContext.isNotEmpty) contextParts.add(productContext);
    if (cartContext.isNotEmpty) contextParts.add(cartContext);

    final systemPrompt = contextParts.isEmpty
        ? _systemPromptPrePurchase
        : '$_systemPromptPrePurchase\n\n--- Store context ---\n${contextParts.join('\n\n')}';

    return _callGroq(
      systemPrompt: systemPrompt,
      userMessage: userMessage,
      history: history,
    );
  }

  // ── Post-purchase / returns chat ─────────────────────────────────────────

  Future<String> sendReturnMessage({
    required String userMessage,
    required List<ChatMessage> history,
    String productCatalogContext = '',
  }) async {
    print('[Chatbot] ── Returns ────────────────────────────────────────');
    print('[Chatbot]   catalog context: ${productCatalogContext.isEmpty ? "none" : "${productCatalogContext.length} chars"}');

    final systemPrompt = productCatalogContext.isEmpty
        ? _systemPromptPostPurchase
        : '$_systemPromptPostPurchase\n\n--- Available products for exchange/alternative suggestions ---\n$productCatalogContext';

    return _callGroq(
      systemPrompt: systemPrompt,
      userMessage: userMessage,
      history: history.where((m) => !m.isLoading).toList(),
    );
  }
}
