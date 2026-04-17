import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../main.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;
  String? _error;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);

    if (_passwordCtrl.text.length < 6) {
      setState(
        () => _error = 'Le mot de passe doit faire au moins 6 caractères.',
      );
      return;
    }

    if (_passwordCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'Les mots de passe ne correspondent pas.');
      return;
    }

    setState(() => _loading = true);

    try {
      await supabase.auth.updateUser(
        UserAttributes(password: _passwordCtrl.text),
      );
      // La navigation est gérée par onAuthStateChange → userUpdated
    } catch (e) {
      setState(() {
        _error = 'Erreur : $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nouveau mot de passe',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.lock_reset_outlined,
                  size: 56,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Choisissez un nouveau mot de passe',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Minimum 6 caractères',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 32),

                // Nouveau mot de passe
                TextField(
                  controller: _passwordCtrl,
                  obscureText: _obscure1,
                  decoration: InputDecoration(
                    labelText: 'Nouveau mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure1
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(() => _obscure1 = !_obscure1),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Confirmer
                TextField(
                  controller: _confirmCtrl,
                  obscureText: _obscure2,
                  decoration: InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure2
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(() => _obscure2 = !_obscure2),
                    ),
                  ),
                  onSubmitted: (_) => _submit(),
                ),

                // Erreur
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ],

                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Modifier le mot de passe'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
