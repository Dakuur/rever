/// Debug script – test Gemini API directly from the command line.
/// Uses only dart:io / dart:convert → NO external packages needed.
///
/// Usage (from repo root):
///   dart run debug_gemini.dart
///   dart run debug_gemini.dart "¿Cuánto cuesta la camiseta roja?"
///
/// Or set the key as an env var:
///   set GEMINI_API_KEY=AIza...
///   dart run debug_gemini.dart

import 'dart:convert';
import 'dart:io';

// gemini-2.0-flash has free-tier quota=0 on this project.
// gemini-2.5-flash is the best available free model.
const _model = 'gemini-2.5-flash';
const _endpoint =
    'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

void _log(String msg) => print('[debug_gemini] $msg');

Future<void> main(List<String> args) async {
  // ── 1. Resolve API key ──────────────────────────────────────────────────
  final apiKey = _resolveApiKey();
  if (apiKey.isEmpty) {
    _log('❌  No API key found.');
    _log('    Set GEMINI_API_KEY env var or add it to .env in the repo root.');
    exit(1);
  }
  _log('✅  API key resolved: ${apiKey.substring(0, 8)}...');

  // ── 2. Build request ────────────────────────────────────────────────────
  final message = args.isNotEmpty ? args.join(' ') : 'Hola, ¿estás funcionando? Di "sí" si me escuchas.';
  _log('Model   : $_model');
  _log('Message : "$message"');

  final body = jsonEncode({
    'contents': [
      {
        'role': 'user',
        'parts': [
          {'text': message}
        ]
      }
    ],
    // BLOCK_NONE on all categories to rule out false-positive safety blocks
    'safetySettings': [
      {'category': 'HARM_CATEGORY_HARASSMENT',        'threshold': 'BLOCK_NONE'},
      {'category': 'HARM_CATEGORY_HATE_SPEECH',       'threshold': 'BLOCK_NONE'},
      {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_NONE'},
      {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_NONE'},
    ],
    'generationConfig': {
      'temperature': 0.7,
    },
  });

  // ── 3. Send HTTP request ────────────────────────────────────────────────
  _log('POST $_endpoint?key=...');
  try {
    final uri = Uri.parse('$_endpoint?key=$apiKey');
    final client = HttpClient();
    final req = await client.postUrl(uri);
    req.headers.set('Content-Type', 'application/json');
    req.write(body);
    final res = await req.close();
    final responseBody = await res.transform(utf8.decoder).join();
    client.close();

    _log('HTTP status: ${res.statusCode}');

    // ── 4. Parse & diagnose ───────────────────────────────────────────────
    _log('─── RAW JSON ──────────────────────────────────────────────────');
    // Pretty-print JSON for readability
    try {
      final parsed = jsonDecode(responseBody);
      print(const JsonEncoder.withIndent('  ').convert(parsed));
    } catch (_) {
      print(responseBody);
    }
    _log('───────────────────────────────────────────────────────────────');

    if (res.statusCode != 200) {
      _log('❌  Non-200 HTTP status → API key invalid, quota exceeded, or network error.');
      exit(5);
    }

    final json = jsonDecode(responseBody) as Map<String, dynamic>;

    // Check for top-level error
    if (json.containsKey('error')) {
      final err = json['error'] as Map<String, dynamic>;
      _log('❌  API returned error: ${err['message']} (code ${err['code']})');
      exit(6);
    }

    // Check for promptFeedback block
    final feedback = json['promptFeedback'] as Map<String, dynamic>?;
    if (feedback != null && feedback['blockReason'] != null) {
      _log('⚠️  Prompt was BLOCKED by safety filters.');
      _log('    blockReason: ${feedback['blockReason']}');
      _log('    safetyRatings: ${jsonEncode(feedback['safetyRatings'])}');
      exit(2);
    }

    // Check candidates
    final candidates = json['candidates'] as List<dynamic>? ?? [];
    if (candidates.isEmpty) {
      _log('⚠️  candidates array is EMPTY – no response generated.');
      exit(3);
    }

    final first = candidates.first as Map<String, dynamic>;
    final finishReason = first['finishReason'] as String? ?? 'UNKNOWN';
    _log('finishReason: $finishReason');

    if (finishReason == 'SAFETY') {
      _log('⚠️  Candidate blocked due to SAFETY.');
      _log('    safetyRatings: ${jsonEncode(first['safetyRatings'])}');
      exit(2);
    }

    // Extract text
    final parts = (first['content']?['parts'] as List<dynamic>?) ?? [];
    final text = parts
        .whereType<Map<String, dynamic>>()
        .map((p) => p['text'] as String? ?? '')
        .join('');

    if (text.trim().isEmpty) {
      _log('⚠️  text is empty despite a valid candidate (finishReason=$finishReason).');
      exit(4);
    }

    _log('✅  SUCCESS — Gemini replied:');
    print('\n$text\n');
  } catch (e, stack) {
    _log('❌  Exception thrown:');
    _log('    $e');
    _log('Stack trace:\n$stack');
    exit(99);
  }
}

/// Reads GEMINI_API_KEY from environment or .env file in the repo root.
String _resolveApiKey() {
  final envKey = Platform.environment['GEMINI_API_KEY'] ?? '';
  if (envKey.isNotEmpty) {
    _log('API key source: system environment variable');
    return envKey;
  }

  // Try .env file relative to script location and cwd
  final candidates = [
    File('.env'),
    File('${Platform.script.resolve('..').toFilePath()}/.env'),
  ];

  for (final f in candidates) {
    if (!f.existsSync()) continue;
    for (final line in f.readAsLinesSync()) {
      final trimmed = line.trim();
      if (trimmed.startsWith('#') || !trimmed.contains('=')) continue;
      final idx = trimmed.indexOf('=');
      final key = trimmed.substring(0, idx).trim();
      final value = trimmed.substring(idx + 1).trim();
      if (key == 'GEMINI_API_KEY' && value.isNotEmpty) {
        _log('API key source: ${f.path}');
        return value;
      }
    }
  }

  return '';
}
