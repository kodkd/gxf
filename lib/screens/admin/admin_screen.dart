import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gxf/core/constants/supabase_admin.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../main.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';

// ─── Provider liste utilisateurs ───
final usersProvider = FutureProvider<List<UserModel>>((ref) async {
  final data = await supabase
      .from('profiles')
      .select()
      .order('created_at', ascending: false);
  return (data as List).map((e) => UserModel.fromJson(e)).toList();
});

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    // Sécurité : seul l'admin accède à cet écran
    if (currentUser == null || !currentUser.isAdmin) {
      return const Scaffold(
        body: Center(child: Text('Accès refusé')),
      );
    }

    final users = ref.watch(usersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddUserDialog(context, ref),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Ajouter un utilisateur'),
      ),
      body: users.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Erreur : $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Aucun utilisateur'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(usersProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _UserCard(
                user: list[i],
                isSelf: list[i].id == currentUser.id,
                onRoleChanged: (newRole) =>
                    _updateRole(context, ref, list[i].id, newRole),
                onToggleActive: () =>
                    _toggleActive(context, ref, list[i]),
                onEdit: () =>
                    _showEditUserDialog(context, ref, list[i]),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _updateRole(
    BuildContext context,
    WidgetRef ref,
    String userId,
    String newRole,
  ) async {
    try {
      await supabase
          .from('profiles')
          .update({'role': newRole})
          .eq('id', userId);
      ref.invalidate(usersProvider);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rôle mis à jour'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
  void _showEditUserDialog(BuildContext context, WidgetRef ref, UserModel user) {
  final nameCtrl  = TextEditingController(text: user.fullName);
  final emailCtrl = TextEditingController(text: user.email);
  bool loading = false;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialog) => AlertDialog(
        title: const Text('Modifier l\'utilisateur',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              // Avatar initiales
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primary.withOpacity(0.15),
                child: Text(
                  user.fullName
                      .split(' ')
                      .take(2)
                      .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
                      .join(),
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 16),

              // Nom complet
              TextField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nom complet',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),

              // Email — informatif uniquement
              TextField(
                controller: emailCtrl,
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  filled: true,
                  fillColor: AppColors.border.withOpacity(0.3),
                  helperText: 'L\'email ne peut pas être modifié',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: loading ? null : () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: loading
                ? null
                : () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    setDialog(() => loading = true);
                    try {
                      await supabase
                          .from('profiles')
                          .update({'full_name': nameCtrl.text.trim()})
                          .eq('id', user.id);

                      ref.invalidate(usersProvider);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profil mis à jour'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    } catch (e) {
                      setDialog(() => loading = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erreur : $e'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
            child: loading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('Enregistrer'),
          ),
        ],
      ),
    ),
  );
}

  Future<void> _toggleActive(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
  ) async {
    final action = user.isActive ? 'désactiver' : 'activer';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${action[0].toUpperCase()}${action.substring(1)} le compte'),
        content: Text(
            'Voulez-vous $action le compte de ${user.fullName} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  user.isActive ? AppColors.error : AppColors.success,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action[0].toUpperCase() + action.substring(1)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await supabase
          .from('profiles')
          .update({'is_active': !user.isActive})
          .eq('id', user.id);
      ref.invalidate(usersProvider);
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'),
            backgroundColor: AppColors.error),
      );
    }
  }

  void _showAddUserDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl     = TextEditingController();
    final emailCtrl    = TextEditingController();
    final passwordCtrl = TextEditingController();
    String role        = 'membre';
    bool loading       = false;
    bool obscure       = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('Nouvel utilisateur',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // Nom complet
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nom complet *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),

                // Email
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),

                // Mot de passe
                TextField(
                  controller: passwordCtrl,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe *',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setDialog(() => obscure = !obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Rôle
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(
                    labelText: 'Rôle',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'membre',
                        child: Text('Membre')),
                    DropdownMenuItem(
                        value: 'chef_projet',
                        child: Text('Chef de projet')),
                    DropdownMenuItem(
                        value: 'admin',
                        child: Text('Administrateur')),
                  ],
                  onChanged: (v) => setDialog(() => role = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: loading ? null : () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      if (nameCtrl.text.trim().isEmpty ||
                          emailCtrl.text.trim().isEmpty ||
                          passwordCtrl.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Remplissez tous les champs (mot de passe min. 6 caractères)'),
                            backgroundColor: AppColors.warning,
                          ),
                        );
                        return;
                      }
                      setDialog(() => loading = true);
                      try {
                        // Créer l'utilisateur via Supabase Auth
                        final res = await supabaseAdmin.auth.admin.createUser(
                          AdminUserAttributes(
                            email:         emailCtrl.text.trim(),
                            password:      passwordCtrl.text,
                            emailConfirm:  true,
                            userMetadata:  {
                              'full_name': nameCtrl.text.trim(),
                            },
                          ),
                        );

                        // Mettre à jour le rôle dans profiles
                        await supabase
                            .from('profiles')
                            .update({
                              'role':      role,
                              'full_name': nameCtrl.text.trim(),
                            })
                            .eq('id', res.user!.id);

                        ref.invalidate(usersProvider);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '${nameCtrl.text.trim()} ajouté avec succès'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialog(() => loading = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erreur : $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
              child: loading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Card utilisateur ───
class _UserCard extends ConsumerWidget {
  final UserModel user;
  final bool isSelf;
  final Function(String) onRoleChanged;
  final VoidCallback onToggleActive;
  final VoidCallback onEdit;          // ← nouveau

  const _UserCard({
    required this.user,
    required this.isSelf,
    required this.onRoleChanged,
    required this.onToggleActive,
    required this.onEdit,             // ← nouveau
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleColor = switch (user.role) {
      'admin'       => AppColors.error,
      'chef_projet' => AppColors.warning,
      _             => AppColors.success,
    };
    final roleLabel = switch (user.role) {
      'admin'       => 'Administrateur',
      'chef_projet' => 'Chef de projet',
      _             => 'Membre',
    };
    final initials = user.fullName
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [

            // Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: user.isActive
                  ? AppColors.primary.withOpacity(0.15)
                  : AppColors.border,
              child: Text(initials,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: user.isActive
                          ? AppColors.primary
                          : AppColors.textMuted)),
            ),
            const SizedBox(width: 12),

            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(user.fullName,
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: user.isActive
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted)),
                      ),
                      if (isSelf)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Moi',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  Text(user.email,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 4),

                  // Badge statut inactif
                  if (!user.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Compte désactivé',
                          style: TextStyle(
                              fontSize: 10,
                              color: AppColors.error,
                              fontWeight: FontWeight.w600)),
                    ),

                  // Dropdown rôle
                  isSelf
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: roleColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(roleLabel,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: roleColor,
                                  fontWeight: FontWeight.w600)),
                        )
                      : DropdownButton<String>(
                          value: user.role,
                          isDense: true,
                          underline: const SizedBox(),
                          style: TextStyle(
                              fontSize: 12,
                              color: roleColor,
                              fontWeight: FontWeight.w600),
                          items: const [
                            DropdownMenuItem(
                                value: 'membre',
                                child: Text('Membre')),
                            DropdownMenuItem(
                                value: 'chef_projet',
                                child: Text('Chef de projet')),
                            DropdownMenuItem(
                                value: 'admin',
                                child: Text('Administrateur')),
                          ],
                          onChanged: (v) {
                            if (v != null && v != user.role) {
                              onRoleChanged(v);
                            }
                          },
                        ),
                ],
              ),
            ),

            // Boutons action
            if (!isSelf)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Modifier
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined,
                        color: AppColors.accent, size: 20),
                    tooltip: 'Modifier le profil',
                  ),
                  // Activer / Désactiver
                  IconButton(
                    onPressed: onToggleActive,
                    icon: Icon(
                      user.isActive
                          ? Icons.person_off_outlined
                          : Icons.person_outlined,
                      color: user.isActive
                          ? AppColors.error
                          : AppColors.success,
                      size: 20,
                    ),
                    tooltip: user.isActive
                        ? 'Désactiver'
                        : 'Activer',
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}