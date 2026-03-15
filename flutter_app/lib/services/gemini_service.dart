import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/chat_message.dart';
import 'shopify_service.dart';

// Groq API — OpenAI-compatible REST endpoint.
// Model: llama-3.3-70b-versatile
const _groqEndpoint = 'https://api.groq.com/openai/v1/chat/completions';
const _groqModel = 'llama-3.3-70b-versatile';

class GeminiService {
  static final GeminiService _instance = GeminiService._();
  factory GeminiService() => _instance;
  GeminiService._();

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
      print('[GroqService] ❌ GROQ_API_KEY is empty – pass --dart-define=GROQ_API_KEY=... at build time');
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
    print('[GroqService] ── Request ──────────────────────────────────────');
    print('[GroqService]   model   : $_groqModel');
    print('[GroqService]   messages: ${messages.length} (incl. system)');
    print('[GroqService]   last msg: "$preview${userMessage.length > 80 ? "…" : ""}"');

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

      print('[GroqService] ── Response ─────────────────────────────────────');
      print('[GroqService]   HTTP status : ${response.statusCode}');

      if (response.statusCode != 200) {
        final errPreview = response.body.substring(0, response.body.length.clamp(0, 400));
        print('[GroqService]   ❌ Error body: $errPreview');
        return 'Error ${response.statusCode} from AI service. Please try again.';
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = json['choices'] as List<dynamic>? ?? [];
      if (choices.isEmpty) {
        print('[GroqService]   ⚠️ Empty choices array. Full body: ${response.body}');
        return 'I received an empty response. Please try again.';
      }

      final finishReason = choices.first['finish_reason'] as String? ?? 'unknown';
      final content = choices.first['message']?['content'] as String? ?? '';
      final usage = json['usage'] as Map<String, dynamic>?;

      print('[GroqService]   finish_reason     : $finishReason');
      print('[GroqService]   reply length      : ${content.length} chars');
      if (usage != null) {
        print('[GroqService]   tokens in/out/total: '
            '${usage['prompt_tokens']}/${usage['completion_tokens']}/${usage['total_tokens']}');
      }

      if (content.trim().isEmpty) {
        print('[GroqService]   ⚠️ Content is empty despite finish_reason=$finishReason');
        return 'I received an empty response. Please try again.';
      }

      print('[GroqService] ✅ Reply ready');
      return content;
    } catch (e, stack) {
      print('[GroqService] ❌ Exception: $e');
      print('[GroqService]   $stack');
      return 'Connection error: ${e.toString()}. Please try again.';
    }
  }

  // ── Pre-purchase chat ────────────────────────────────────────────────────

  Future<String> sendPrePurchaseMessage({
    required String userMessage,
    required List<ChatMessage> history,
    String cartContext = '',
  }) async {
    print('[GroqService] ── Pre-purchase ──────────────────────────────────');
    print('[GroqService]   cart context : ${cartContext.isEmpty ? "none" : "${cartContext.length} chars"}');

    String productContext = '';
    try {
      productContext = await ShopifyService().buildProductContext(userMessage);
    } catch (e) {
      print('[GroqService]   ⚠️ Shopify product context failed: $e');
    }
    print('[GroqService]   product context: ${productContext.isEmpty ? "none" : "${productContext.length} chars"}');

    // Build enriched system prompt with live context appended
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
    print('[GroqService] ── Returns ────────────────────────────────────────');
    print('[GroqService]   catalog context: ${productCatalogContext.isEmpty ? "none" : "${productCatalogContext.length} chars"}');

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
