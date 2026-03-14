/// Debug script – test Groq API directly from the command line.
/// Uses only dart:io / dart:convert → NO external packages needed.
///
/// Usage (from repo root):
///   dart run debug_groq.dart
///   dart run debug_groq.dart "¿Cuánto cuesta la camiseta?"

import 'dart:convert';
import 'dart:io';

const _model = 'llama-3.3-70b-versatile';
const _endpoint = 'https://api.groq.com/openai/v1/chat/completions';

void _log(String msg) => print('[debug_groq] $msg');

Future<void> main(List<String> args) async {
  final apiKey = _resolveApiKey();
  if (apiKey.isEmpty) {
    _log('❌  No API key found. Set GROQ_API_KEY in .env or as env var.');
    exit(1);
  }
  _log('✅  API key: ${apiKey.substring(0, 8)}...');

  final message = args.isNotEmpty ? args.join(' ') : 'Hola, ¿estás funcionando? Responde en español.';
  _log('Model  : $_model');
  _log('Message: "$message"');

  final body = jsonEncode({
    'model': _model,
    'messages': [
      {'role': 'system', 'content': 'Eres un asistente de tienda Shopify llamado REVER.'},
      {'role': 'user',   'content': message},
    ],
    'temperature': 0.7,
    'max_completion_tokens': 512,
    'stream': false,
  });

  _log('POST $_endpoint');
  try {
    final client = HttpClient();
    final req = await client.postUrl(Uri.parse(_endpoint));
    req.headers.set('Content-Type', 'application/json');
    req.headers.set('Authorization', 'Bearer $apiKey');
    req.write(body);
    final res = await req.close();
    final responseBody = await res.transform(utf8.decoder).join();
    client.close();

    _log('HTTP status: ${res.statusCode}');
    _log('─── RAW JSON ──────────────────────────────────────────────────');
    try {
      print(const JsonEncoder.withIndent('  ').convert(jsonDecode(responseBody)));
    } catch (_) {
      print(responseBody);
    }
    _log('───────────────────────────────────────────────────────────────');

    if (res.statusCode != 200) {
      _log('❌  Non-200 status → check API key or model name.');
      exit(2);
    }

    final json = jsonDecode(responseBody) as Map<String, dynamic>;
    final choices = json['choices'] as List<dynamic>? ?? [];
    if (choices.isEmpty) {
      _log('⚠️  choices is EMPTY.');
      exit(3);
    }

    final content = choices.first['message']?['content'] as String? ?? '';
    final finishReason = choices.first['finish_reason'] ?? 'unknown';
    _log('finish_reason: $finishReason');

    if (content.trim().isEmpty) {
      _log('⚠️  content is empty.');
      exit(4);
    }

    _log('✅  SUCCESS — Groq replied:');
    print('\n$content\n');
  } catch (e, stack) {
    _log('❌  Exception: $e');
    _log('Stack:\n$stack');
    exit(99);
  }
}

String _resolveApiKey() {
  final envKey = Platform.environment['GROQ_API_KEY'] ?? '';
  if (envKey.isNotEmpty) {
    _log('API key source: system environment');
    return envKey;
  }
  for (final f in [File('.env'), File('${Platform.script.resolve('..').toFilePath()}/.env')]) {
    if (!f.existsSync()) continue;
    for (final line in f.readAsLinesSync()) {
      final t = line.trim();
      if (t.startsWith('#') || !t.contains('=')) continue;
      final idx = t.indexOf('=');
      if (t.substring(0, idx).trim() == 'GROQ_API_KEY') {
        _log('API key source: ${f.path}');
        return t.substring(idx + 1).trim();
      }
    }
  }
  return '';
}
