import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/chat_message.dart';
import 'shopify_service.dart';

// Uses the Gemini REST API directly via HTTP instead of the google_generative_ai
// package, which has known web (dart2js) inconsistencies in v0.4.x.
// This is identical in behaviour to debug_gemini.dart, which is confirmed working.

const _geminiModel = 'gemini-2.5-flash';
const _geminiEndpoint =
    'https://generativelanguage.googleapis.com/v1beta/models/$_geminiModel:generateContent';

// BLOCK_NONE on all categories to avoid false-positive safety blocks.
const _safetySettings = [
  {'category': 'HARM_CATEGORY_HARASSMENT',        'threshold': 'BLOCK_NONE'},
  {'category': 'HARM_CATEGORY_HATE_SPEECH',       'threshold': 'BLOCK_NONE'},
  {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_NONE'},
  {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_NONE'},
];

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
  Future<String> _callGemini({
    required String systemPrompt,
    required String userMessage,
    required List<ChatMessage> history,
  }) async {
    final apiKey = AppConfig.geminiApiKey;
    if (apiKey.isEmpty) {
      print('[GeminiService] ❌ GEMINI_API_KEY is empty – check --dart-define at build time.');
      return 'Configuration error: API key not set. Please contact support.';
    }

    // Build contents array: system + history + current user message
    final contents = <Map<String, dynamic>>[];

    // System instruction as first user turn (v1beta REST style)
    contents.add({
      'role': 'user',
      'parts': [{'text': '[SYSTEM]\n$systemPrompt\n[/SYSTEM]'}],
    });
    contents.add({
      'role': 'model',
      'parts': [{'text': 'Understood. I will follow those instructions.'}],
    });

    // Previous conversation history
    for (final msg in history.where((m) => !m.isLoading)) {
      contents.add({
        'role': msg.role == MessageRole.user ? 'user' : 'model',
        'parts': [{'text': msg.content}],
      });
    }

    // Current user message
    contents.add({
      'role': 'user',
      'parts': [{'text': userMessage}],
    });

    final body = jsonEncode({
      'contents': contents,
      'safetySettings': _safetySettings,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 1024,
      },
    });

    print('[GeminiService] POST $_geminiEndpoint | model=$_geminiModel'
        ' | history=${history.length} msgs'
        ' | msg="${userMessage.substring(0, userMessage.length.clamp(0, 80))}"');

    final uri = Uri.parse('$_geminiEndpoint?key=$apiKey');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    print('[GeminiService] HTTP ${response.statusCode}');

    if (response.statusCode != 200) {
      print('[GeminiService] ❌ Non-200: ${response.body}');
      return 'Error ${response.statusCode} from AI service. Please try again.';
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    // Check for API-level error
    if (json.containsKey('error')) {
      final err = json['error'] as Map<String, dynamic>;
      print('[GeminiService] ❌ API error: ${err['message']}');
      return 'AI service error: ${err['message']}. Please try again.';
    }

    // Check for prompt block
    final feedback = json['promptFeedback'] as Map<String, dynamic>?;
    if (feedback != null && feedback['blockReason'] != null) {
      print('[GeminiService] ⚠️ Prompt blocked: ${feedback['blockReason']}');
      return 'I could not process that request. Please rephrase your question.';
    }

    final candidates = json['candidates'] as List<dynamic>? ?? [];
    if (candidates.isEmpty) {
      print('[GeminiService] ⚠️ candidates is EMPTY. Full response: ${response.body}');
      return 'I received an empty response. Please try again.';
    }

    final first = candidates.first as Map<String, dynamic>;
    final finishReason = first['finishReason'] as String? ?? 'UNKNOWN';
    print('[GeminiService] finishReason: $finishReason');

    if (finishReason == 'SAFETY') {
      print('[GeminiService] ⚠️ Candidate blocked by SAFETY: ${first['safetyRatings']}');
      return 'I could not process that request due to content policies.';
    }

    final parts = (first['content']?['parts'] as List<dynamic>?) ?? [];
    final text = parts
        .whereType<Map<String, dynamic>>()
        .map((p) => p['text'] as String? ?? '')
        .join('');

    if (text.trim().isEmpty) {
      print('[GeminiService] ⚠️ text is empty. finishReason=$finishReason');
      return 'I received an empty response. Please try again.';
    }

    print('[GeminiService] ✅ Reply (${text.length} chars)');
    return text;
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
      print('[GeminiService] Shopify context fetch failed: $e');
    }

    final contextualMessage = productContext.isNotEmpty
        ? '$userMessage\n\n[Store context]\n$productContext'
        : userMessage;

    try {
      return await _callGemini(
        systemPrompt: _systemPromptPrePurchase,
        userMessage: contextualMessage,
        history: history,
      );
    } catch (e, stack) {
      print('[GeminiService] ❌ Unhandled error in sendPrePurchaseMessage: $e\n$stack');
      return 'Connection error: ${e.toString()}. Please try again.';
    }
  }

  // ── Post-purchase / returns chat ─────────────────────────────────────────
  Future<String> sendReturnMessage({
    required String userMessage,
    required List<ChatMessage> history,
  }) async {
    try {
      return await _callGemini(
        systemPrompt: _systemPromptPostPurchase,
        userMessage: userMessage,
        history: history,
      );
    } catch (e, stack) {
      print('[GeminiService] ❌ Unhandled error in sendReturnMessage: $e\n$stack');
      return 'Connection error: ${e.toString()}. Please try again.';
    }
  }
}
