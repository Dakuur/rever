import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

import 'firebase_options.dart';
import 'models/chat_message.dart';
import 'screens/chat_screen.dart';
import 'services/language_service.dart';
import 'theme/rever_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LanguageService().init();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase may fail inside a Shopify iframe due to auth-domain restrictions.
    // The chat still works without Firebase (conversations won't be persisted).
    print('[main] Firebase init failed (non-fatal): $e');
  }

  runApp(const ReverApp());
}

class ReverApp extends StatelessWidget {
  const ReverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'REVER Assistant',
      debugShowCheckedModeBanner: false,
      theme: const CupertinoThemeData(
        primaryColor: ReverTheme.accent,
        brightness: Brightness.light,
        textTheme: CupertinoTextThemeData(
          textStyle: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 15,
            color: ReverTheme.textPrimary,
          ),
        ),
      ),
      home: const _AppShell(),
    );
  }
}

class _AppShell extends StatelessWidget {
  const _AppShell();

  @override
  Widget build(BuildContext context) {
    // Auth state observed; chat works anonymously too.
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        return const ChatScreen(mode: ChatMode.prePurchase);
      },
    );
  }
}
