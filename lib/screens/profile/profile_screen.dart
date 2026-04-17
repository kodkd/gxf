import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gxf/main.dart';
import '../../models/user_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../admin/admin_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _uploadingAvatar = false;

  Future<void> _pickAndUploadAvatar() async {
    setState(() => _uploadingAvatar = true);
    try {
      File? file;

      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );
        if (result == null || result.files.isEmpty) {
          setState(() => _uploadingAvatar = false);
          return;
        }
        file = File(result.files.single.path!);
      } else {
        final picker = ImagePicker();
        final picked = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 512,
          maxHeight: 512,
          imageQuality: 80,
        );
        if (picked == null) {
          setState(() => _uploadingAvatar = false);
          return;
        }
        file = File(picked.path);
      }

      final userId = supabase.auth.currentUser!.id;
      final fileName = '$userId/avatar.jpg';

      await supabase.storage
          .from('avatars')
          .upload(fileName, file, fileOptions: const FileOptions(upsert: true));

      final url = supabase.storage.from('avatars').getPublicUrl(fileName);

      await supabase
          .from('profiles')
          .update({
            'avatar_url': '$url?t=${DateTime.now().millisecondsSinceEpoch}',
          })
          .eq('id', userId);

      ref.invalidate(currentUserProvider);
      ref.invalidate(authNotifierProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo mise à jour'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploadingAvatar = false);
      }
    }
  }

  void _showEditProfile(BuildContext context, UserModel user) {
    final nameCtrl = TextEditingController(text: user.fullName);
    final usernameCtrl = TextEditingController(text: user.username ?? '');
    bool loading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Modifier le profil',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

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

              // Username
              TextField(
                controller: usernameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom d\'utilisateur',
                  prefixIcon: Icon(Icons.alternate_email),
                  hintText: 'ex: jean.dupont',
                  helperText: 'Permet de se connecter sans email',
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: loading
                    ? null
                    : () async {
                        if (nameCtrl.text.trim().isEmpty) return;
                        setModal(() => loading = true);
                        try {
                          await ref
                              .read(authNotifierProvider.notifier)
                              .updateProfile(
                                fullName: nameCtrl.text.trim(),
                                username: usernameCtrl.text.trim(),
                              );
                          ref.invalidate(currentUserProvider);
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
                          setModal(() => loading = false);
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
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final tasks = ref.watch(allTasksProvider).valueOrNull ?? [];

    return userAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Erreur : $e'))),
      data: (user) {
        if (user == null) return const Scaffold(body: SizedBox());

        final myTasks = tasks.where((t) => t.assigneeId == user.id).toList();
        final doneTasks = myTasks.where((t) => t.status == 'termine').length;
        final lateTasks = myTasks.where((t) => t.isLate).length;
        final isAdmin = user.isAdmin;

        final roleLabel = switch (user.role) {
          'admin' => 'Administrateur',
          'chef_projet' => 'Chef de projet',
          _ => 'Membre',
        };
        final roleColor = switch (user.role) {
          'admin' => AppColors.error,
          'chef_projet' => AppColors.warning,
          _ => AppColors.success,
        };

        final initials = user.fullName
            .split(' ')
            .take(2)
            .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
            .join();

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Mon profil',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _showEditProfile(context, user),
                tooltip: 'Modifier le profil',
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Avatar ──
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        // Photo ou initiales
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: AppColors.primary.withOpacity(0.15),
                          backgroundImage: user.avatarUrl != null
                              ? NetworkImage(user.avatarUrl!)
                              : null,
                          child: user.avatarUrl == null
                              ? Text(
                                  initials,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                )
                              : null,
                        ),

                        // Bouton upload
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _uploadingAvatar
                                ? null
                                : _pickAndUploadAvatar,
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.primary,
                              child: _uploadingAvatar
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.camera_alt,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Nom
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Username si défini
                    if (user.username != null) ...[
                      Text(
                        '@${user.username}',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],

                    Text(
                      user.email,
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 8),

                    // Badge rôle
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        roleLabel,
                        style: TextStyle(
                          color: roleColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Stats ──
              Row(
                children: [
                  _StatCard('Mes tâches', '${myTasks.length}', Icons.task_alt),
                  const SizedBox(width: 12),
                  _StatCard(
                    'Terminées',
                    '$doneTasks',
                    Icons.check_circle_outline,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    'En retard',
                    '$lateTasks',
                    Icons.warning_amber_outlined,
                    color: lateTasks > 0 ? AppColors.error : AppColors.success,
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── Paramètres ──
              const Text(
                'Paramètres',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 8),

              Card(
                child: Column(
                  children: [
                    // Admin uniquement
                    if (isAdmin) ...[
                      _SettingsTile(
                        icon: Icons.admin_panel_settings_outlined,
                        label: 'Gestion des utilisateurs',
                        color: AppColors.primary,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminScreen(),
                          ),
                        ),
                      ),
                      const Divider(height: 1, indent: 56),
                    ],

                    _SettingsTile(
                      icon: Icons.lock_outline,
                      label: 'Changer le mot de passe',
                      onTap: () => _showChangePassword(context, ref),
                    ),
                    const Divider(height: 1, indent: 56),
                    _SettingsTile(
                      icon: Icons.info_outline,
                      label: 'Version de l\'application',
                      trailing: const Text(
                        '1.0.0',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      onTap: () {},
                    ),
                    const Divider(height: 1, indent: 56),
                    _SettingsTile(
                      icon: Icons.logout,
                      label: 'Se déconnecter',
                      color: AppColors.error,
                      onTap: () => _confirmLogout(context, ref),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showChangePassword(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouveau mot de passe'),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Nouveau mot de passe'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.length < 6) return;
              await ref
                  .read(authNotifierProvider.notifier)
                  .updatePassword(ctrl.text);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mot de passe mis à jour'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authNotifierProvider.notifier).signOut();
            },
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );
  }
}

// ── Widgets réutilisables ──

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(
    this.label,
    this.value,
    this.icon, {
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.textPrimary,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color, size: 22),
      title: Text(label, style: TextStyle(color: color, fontSize: 14)),
      trailing:
          trailing ??
          const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
    );
  }
}
