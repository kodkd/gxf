import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/project_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';

class ProjectFormScreen extends ConsumerStatefulWidget {
  const ProjectFormScreen({super.key});

  @override
  ConsumerState<ProjectFormScreen> createState() =>
      _ProjectFormScreenState();
}

class _ProjectFormScreenState extends ConsumerState<ProjectFormScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  UserModel? _selectedChef;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => isStart ? _startDate = picked : _endDate = picked);
    }
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le nom du projet est obligatoire'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(projectsNotifierProvider.notifier).createProject(
        name:        _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        startDate:   _startDate?.toIso8601String().split('T').first,
        endDate:     _endDate?.toIso8601String().split('T').first,
        chefId:      _selectedChef?.id,
      );
      if (mounted) Navigator.pop(context);
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
    final users = ref.watch(allUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau projet',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // Nom
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom du projet *',
                prefixIcon: Icon(Icons.folder_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.notes_outlined),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),

            // Chef de projet (optionnel)
            users.when(
              loading: () => const LinearProgressIndicator(),
              error:   (e, _) => const SizedBox(),
              data: (list) {
                final chefs = list
                    .where((u) =>
                        u.role == 'chef_projet' || u.role == 'admin')
                    .toList();
                return DropdownButtonFormField<UserModel?>(
                  value: _selectedChef,
                  decoration: const InputDecoration(
                    labelText: 'Chef de projet (optionnel)',
                    prefixIcon: Icon(Icons.manage_accounts_outlined),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('— Aucun pour l\'instant —',
                          style: TextStyle(color: AppColors.textMuted)),
                    ),
                    ...chefs.map(
                      (u) => DropdownMenuItem(
                        value: u,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor:
                                  AppColors.primary.withOpacity(0.15),
                              child: Text(
                                u.fullName
                                    .split(' ')
                                    .take(2)
                                    .map((w) => w.isNotEmpty
                                        ? w[0].toUpperCase()
                                        : '')
                                    .join(),
                                style: const TextStyle(
                                    fontSize: 9,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(u.fullName),
                          ],
                        ),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _selectedChef = v),
                );
              },
            ),
            const SizedBox(height: 16),

            // Dates
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'Date de début',
                    date: _startDate,
                    onTap: () => _pickDate(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateField(
                    label: 'Date de fin',
                    date: _endDate,
                    onTap: () => _pickDate(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Créer le projet'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(
          date != null
              ? '${date!.day}/${date!.month}/${date!.year}'
              : 'Choisir',
          style: TextStyle(
              color:
                  date != null ? AppColors.textPrimary : AppColors.textMuted),
        ),
      ),
    );
  }
}