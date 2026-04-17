import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _loginCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _loginCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ref
          .read(authNotifierProvider.notifier)
          .signIn(_loginCtrl.text.trim(), _passwordCtrl.text.trim());
    } catch (e) {
      setState(() => _error = e.toString().contains('introuvable')
          ? 'Nom d\'utilisateur introuvable'
          : 'Email/username ou mot de passe incorrect');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.business_center_rounded,
                    size: 56, color: AppColors.primary),
                const SizedBox(height: 16),
                Text('GXF',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                    textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text('Gestion interne d\'entreprise',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 40),

                // Email ou username
                TextField(
                  controller: _loginCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email ou nom d\'utilisateur',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),

                // Mot de passe
                TextField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscure = !_obscure),
                    ),
                  ),
                  onSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 8),

                // Erreur
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(_error!,
                        style:
                            const TextStyle(color: AppColors.error),
                        textAlign: TextAlign.center),
                  ),

                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Se connecter'),
                ),
                const SizedBox(height: 16),

                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const ForgotPasswordScreen()),
                  ),
                  child: const Text('Mot de passe oublié ?'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}