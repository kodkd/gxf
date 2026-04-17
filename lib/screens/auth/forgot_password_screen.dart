import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../main.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent    = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_emailCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await supabase.auth.resetPasswordForEmail(
        _emailCtrl.text.trim(),
      );
      setState(() => _sent = true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mot de passe oublié')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: _sent ? _SuccessView() : _FormView(
              emailCtrl: _emailCtrl,
              loading:   _loading,
              onSubmit:  _submit,
            ),
          ),
        ),
      ),
    );
  }
}

class _FormView extends StatelessWidget {
  final TextEditingController emailCtrl;
  final bool loading;
  final VoidCallback onSubmit;

  const _FormView({
    required this.emailCtrl,
    required this.loading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.lock_reset_outlined,
            size: 56, color: AppColors.primary),
        const SizedBox(height: 16),
        const Text('Réinitialisation',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          'Entrez votre email. Vous recevrez un lien pour réinitialiser votre mot de passe.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: loading ? null : onSubmit,
          child: loading
              ? const SizedBox(
                  height: 20, width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Text('Envoyer le lien'),
        ),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.mark_email_read_outlined,
            size: 56, color: AppColors.success),
        const SizedBox(height: 16),
        const Text('Email envoyé !',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          'Vérifiez votre boîte mail et suivez le lien pour réinitialiser votre mot de passe.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Retour à la connexion'),
        ),
      ],
    );
  }
}