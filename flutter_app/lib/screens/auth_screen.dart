import 'package:flutter/cupertino.dart';
import '../services/firebase_service.dart';
import '../theme/rever_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _firebaseSvc = FirebaseService();
  bool _isLoading = false;
  String? _error;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await _firebaseSvc.signInWithGoogle();
      // Navigation handled by StreamBuilder in main.dart
    } catch (e) {
      setState(() {
        _error = 'Sign in failed. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: ReverTheme.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [ReverTheme.accent, Color(0xFF9B96FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: ReverTheme.floatingShadow,
                ),
                child: const Center(
                  child: Text('R',
                      style: TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 24),
              Text('REVER Assistant',
                  style: ReverTheme.headingLarge),
              const SizedBox(height: 8),
              Text(
                'Sign in to save your conversation history\nand track your returns.',
                style: ReverTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // Google sign-in button
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: ReverTheme.primary,
                  borderRadius:
                      BorderRadius.circular(ReverTheme.radiusMedium),
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  child: _isLoading
                      ? const CupertinoActivityIndicator(
                          color: CupertinoColors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _GoogleLogo(),
                            const SizedBox(width: 10),
                            const Text(
                              'Continue with Google',
                              style: TextStyle(
                                  color: CupertinoColors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: const TextStyle(
                        color: ReverTheme.error, fontSize: 13)),
              ],
              const SizedBox(height: 24),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  // Skip auth – anonymous user
                  Navigator.of(context).pop();
                },
                child: const Text('Continue without signing in',
                    style: TextStyle(
                        color: ReverTheme.textSecondary, fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(2),
      ),
      child: const Center(
        child: Text('G',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF4285F4))),
      ),
    );
  }
}
