import 'package:flutter_test/flutter_test.dart';
import 'package:rever_chat/services/language_service.dart';

void main() {
  late LanguageService lang;

  setUp(() {
    lang = LanguageService();
    lang.resetForTesting();
  });

  group('LanguageService – Spanish detection', () {
    test('detects Spanish from ñ character', () {
      lang.refineFromText('quiero devolver esta camiseta de niño');
      expect(lang.code, 'es');
    });

    test('detects Spanish from "hola"', () {
      lang.refineFromText('hola tengo un problema');
      expect(lang.code, 'es');
    });

    test('detects Spanish from "gracias"', () {
      lang.refineFromText('gracias por tu ayuda');
      expect(lang.code, 'es');
    });

    test('detects Spanish from "quiero"', () {
      lang.refineFromText('quiero hacer una devolución');
      expect(lang.code, 'es');
    });

    test('detects Spanish from "pedido"', () {
      lang.refineFromText('mi pedido llegó dañado');
      expect(lang.code, 'es');
    });

    test('detects Spanish from ¿ character', () {
      lang.refineFromText('¿puedes ayudarme?');
      expect(lang.code, 'es');
    });
  });

  group('LanguageService – French detection', () {
    test('detects French from ç character (no Spanish ambiguity)', () {
      // Avoid ' un ', ' le ', ' la ' which are also in Spanish list
      lang.refineFromText('votre commande reçue merci beaucoup');
      expect(lang.code, 'fr');
    });

    test('detects French from "bonjour"', () {
      lang.refineFromText('bonjour comment allez vous');
      expect(lang.code, 'fr');
    });

    test('detects French from "merci"', () {
      lang.refineFromText('merci pour votre aide');
      expect(lang.code, 'fr');
    });

    test('detects French from "retour" keyword', () {
      // Ensure no Spanish ' un ' etc. trigger first
      lang.refineFromText('bonjour je veux faire retour');
      expect(lang.code, 'fr');
    });

    test('detects French from "commande"', () {
      lang.refineFromText('ma commande est arrivée');
      expect(lang.code, 'fr');
    });
  });

  group('LanguageService – German detection', () {
    test('detects German from ü character', () {
      lang.refineFromText('ich möchte eine Rückgabe');
      expect(lang.code, 'de');
    });

    test('detects German from "bestellung"', () {
      lang.refineFromText('meine bestellung ist falsch');
      expect(lang.code, 'de');
    });

    test('detects German from "hallo" + "ich"', () {
      lang.refineFromText('hallo ich brauche hilfe');
      expect(lang.code, 'de');
    });

    test('detects German from ß character', () {
      lang.refineFromText('das ist heißer Kaffee');
      expect(lang.code, 'de');
    });

    test('detects German from "rückgabe"', () {
      lang.refineFromText('ich möchte rückgabe machen');
      expect(lang.code, 'de');
    });
  });

  group('LanguageService – Portuguese detection', () {
    test('detects Portuguese from ã character (no ç)', () {
      // Avoid 'ç' which would match French first; use ã only
      lang.refineFromText('quero uma irmã bonita');
      expect(lang.code, 'pt');
    });

    test('detects Portuguese from "olá"', () {
      // Avoid ' de ' which is in Spanish list
      lang.refineFromText('olá obrigado por tudo');
      expect(lang.code, 'pt');
    });

    test('detects Portuguese from "obrigado"', () {
      lang.refineFromText('obrigado pela sua ajuda');
      expect(lang.code, 'pt');
    });

    test('detects Portuguese from "obrigada"', () {
      lang.refineFromText('muito obrigada amiga');
      expect(lang.code, 'pt');
    });
  });

  group('LanguageService – Italian detection', () {
    test('detects Italian from "ciao"', () {
      lang.refineFromText('ciao come stai oggi');
      expect(lang.code, 'it');
    });

    test('detects Italian from "grazie"', () {
      lang.refineFromText('grazie mille per aiuto');
      expect(lang.code, 'it');
    });

    test('detects Italian from "voglio"', () {
      // Avoid 'è' which matches French first; avoid ' un ' (Spanish)
      lang.refineFromText('voglio fare reso adesso');
      expect(lang.code, 'it');
    });

    test('detects Italian from "reso"', () {
      // Avoid ' un ' (Spanish ambiguity); use ' il ' + 'reso'
      lang.refineFromText('per favore fate reso grazie');
      expect(lang.code, 'it');
    });
  });

  group('LanguageService – Dutch detection', () {
    test('detects Dutch from "bestelling"', () {
      lang.refineFromText('mijn bestelling is verkeerd');
      expect(lang.code, 'nl');
    });

    test('detects Dutch from " ik " keyword', () {
      // Avoid 'retour' (French) and German 'hallo'; ' ik ' with spaces
      lang.refineFromText('dat ik het wil kopen');
      expect(lang.code, 'nl');
    });
  });

  group('LanguageService – English / no detection', () {
    test('keeps English default for plain English text', () {
      lang.refineFromText('hello I need help with my order');
      expect(lang.code, 'en');
    });

    test('keeps English for text with no known patterns', () {
      lang.refineFromText('I want to return this product');
      expect(lang.code, 'en');
    });

    test('keeps English when no language is matched', () {
      lang.refineFromText('xyz randomtext nothing special here');
      expect(lang.code, 'en');
    });
  });

  group('LanguageService – once-only refinement', () {
    test('refineFromText only runs once per session', () {
      lang.refineFromText('hola quiero devolver');
      expect(lang.code, 'es');

      // Second call with French should NOT change the code
      lang.refineFromText('bonjour merci');
      expect(lang.code, 'es'); // still Spanish
    });

    test('after resetForTesting, can refine again', () {
      lang.refineFromText('hola');
      expect(lang.code, 'es');

      lang.resetForTesting();
      lang.refineFromText('bonjour');
      expect(lang.code, 'fr');
    });
  });

  group('LanguageService – code getter', () {
    test('default code is en before any refinement', () {
      expect(lang.code, 'en');
    });
  });
}
