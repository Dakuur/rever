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

  // ── Core HTTP call ───────────────────────────────────────────────────────

  Future<String> _callGroq({
    required String systemPrompt,
    required String userMessage,
    required List<ChatMessage> history,
  }) async {
    final apiKey = AppConfig.groqApiKey;
    if (apiKey.isEmpty) {
      print('[GroqService] ❌ GROQ_API_KEY is empty – check --dart-define at build time.');
      return 'Configuration error: API key not set. Please contact support.';
    }

    // Build OpenAI-format messages array.
    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': systemPrompt},
    ];

    // Previous conversation history (skip loading placeholders).
    for (final msg in history.where((m) => !m.isLoading)) {
      messages.add({
        'role': msg.role == MessageRole.user ? 'user' : 'assistant',
        'content': msg.content,
      });
    }

    // Current user message (already appended to history before this call,
    // so we don't add it again — history includes it as the last entry).

    print('[GroqService] POST $_groqEndpoint | model=$_groqModel'
        ' | messages=${messages.length}'
        ' | last="${userMessage.substring(0, userMessage.length.clamp(0, 80))}"');

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

      print('[GroqService] HTTP ${response.statusCode}');

      if (response.statusCode != 200) {
        print('[GroqService] ❌ Error: ${response.body.substring(0, response.body.length.clamp(0, 400))}');
        return 'Error ${response.statusCode} from AI service. Please try again.';
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      // OpenAI-format response: choices[0].message.content
      final choices = json['choices'] as List<dynamic>? ?? [];
      if (choices.isEmpty) {
        print('[GroqService] ⚠️ choices is EMPTY. Full response: ${response.body}');
        return 'I received an empty response. Please try again.';
      }

      final finishReason = choices.first['finish_reason'] as String? ?? 'unknown';
      print('[GroqService] finish_reason: $finishReason');

      final content = choices.first['message']?['content'] as String? ?? '';
      if (content.trim().isEmpty) {
        print('[GroqService] ⚠️ content is empty. finish_reason=$finishReason');
        return 'I received an empty response. Please try again.';
      }

      print('[GroqService] ✅ Reply (${content.length} chars)');
      return content;
    } catch (e, stack) {
      print('[GroqService] ❌ Exception: $e\n$stack');
      return 'Connection error: ${e.toString()}. Please try again.';
    }
  }

  // ── Pre-purchase chat ────────────────────────────────────────────────────

  Future<String> sendPrePurchaseMessage({
    required String userMessage,
    required List<ChatMessage> history,
  }) async {
    String productContext = '';
    try {
      productContext = await ShopifyService().buildProductContext(userMessage);
    } catch (e) {
      print('[GroqService] Shopify context fetch failed: $e');
    }

    final contextualMessage = productContext.isNotEmpty
        ? '$userMessage\n\n[Store context]\n$productContext'
        : userMessage;

    // Replace last user message in history with the contextual version.
    final enrichedHistory = [
      ...history.where((m) => !m.isLoading && m.content != userMessage),
      ChatMessage(
        id: 'ctx',
        role: MessageRole.user,
        content: contextualMessage,
        timestamp: DateTime.now(),
      ),
    ];

    return _callGroq(
      systemPrompt: _systemPromptPrePurchase,
      userMessage: contextualMessage,
      history: enrichedHistory,
    );
  }

  // ── Post-purchase / returns chat ─────────────────────────────────────────

  Future<String> sendReturnMessage({
    required String userMessage,
    required List<ChatMessage> history,
  }) async {
    return _callGroq(
      systemPrompt: _systemPromptPostPurchase,
      userMessage: userMessage,
      history: history.where((m) => !m.isLoading).toList(),
    );
  }
}
