import 'dart:ui';

/// Detects and stores the user's preferred language for the session.
///
/// Detection happens in two steps:
///   1. Platform / browser locale on app start.
///   2. One-time heuristic refinement from the user's first typed message.
class LanguageService {
  static final LanguageService _instance = LanguageService._();
  factory LanguageService() => _instance;
  LanguageService._();

  static const _supported = {'en', 'es', 'fr', 'de', 'pt', 'it', 'nl'};

  String _code = 'en';
  bool _refinedFromText = false;

  /// Call once before `runApp` to read the platform / browser locale.
  void init() {
    final browser =
        PlatformDispatcher.instance.locale.languageCode.toLowerCase();
    _code = _supported.contains(browser) ? browser : 'en';
    print('[Language] Platform locale: $browser -> using: $_code');
  }

  /// Refines the detected language from the user's first typed message.
  /// Only runs once per session.
  void refineFromText(String text) {
    if (_refinedFromText) return;
    _refinedFromText = true;
    final detected = _detectFromText(text);
    if (detected != null && detected != _code) {
      print('[Language] Refined from user text: $_code -> $detected');
      _code = detected;
    }
  }

  /// Current ISO-639-1 language code (e.g. 'en', 'es', 'fr').
  String get code => _code;

  // ── Heuristic text detection ──────────────────────────────────────────────

  String? _detectFromText(String text) {
    final t = text.toLowerCase();

    if (_hasPattern(t, r'[ñ¿¡]') ||
        _hasWords(t, [
          'hola', 'gracias', 'quiero', 'devolver', 'pedido',
          'talla', ' el ', ' la ', ' los ', ' las ', ' un ', ' una ', ' de ',
        ])) {
      return 'es';
    }
    if (_hasPattern(t, r'[çèêëàâœùûî]') ||
        _hasWords(t, [
          'bonjour', 'merci', 'salut', 'commande', ' je ', ' le ',
          ' la ', ' les ', ' un ', ' une ', 'retour',
        ])) {
      return 'fr';
    }
    if (_hasPattern(t, r'[äöüß]') ||
        _hasWords(t, [
          'hallo', 'danke', 'bitte', 'bestellung', ' ich ',
          ' das ', ' die ', ' der ', 'rückgabe',
        ])) {
      return 'de';
    }
    if (_hasPattern(t, r'[ãõâêôçà]') ||
        _hasWords(t, [
          'olá', 'ola', 'obrigado', 'obrigada', 'quero', 'devolução',
        ])) {
      return 'pt';
    }
    if (_hasPattern(t, r'[àèéìòù]') ||
        _hasWords(t, [
          'ciao', 'grazie', 'ordine', 'voglio', ' sono ', ' il ', 'reso',
        ])) {
      return 'it';
    }
    if (_hasWords(t, ['hallo', 'dank', 'bestelling', ' ik ', ' het '])) {
      return 'nl';
    }
    return null;
  }

  bool _hasPattern(String text, String pattern) =>
      RegExp(pattern).hasMatch(text);

  bool _hasWords(String text, List<String> words) =>
      words.any((w) => text.contains(w));
}
