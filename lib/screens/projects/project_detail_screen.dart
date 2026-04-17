import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/etape_model.dart';
import '../../models/task_model.dart';
import '../../providers/etape_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/project_provider.dart';
import '../../providers/auth_provider.dart';
import '../tasks/task_detail_screen.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final String projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(projectDetailProvider(widget.projectId));
    final etapes  = ref.watch(etapesNotifierProvider(widget.projectId));

    return Scaffold(
      appBar: AppBar(
        title: project.when(
          data:    (p) => Text(p.name,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          loading: () => const Text('Chargement...'),
          error:   (e, _) => const Text('Erreur'),
        ),
        actions: [
          project.when(
            data: (p) => IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () => _confirmDeleteProject(context, ref, p.name),
            ),
            loading: () => const SizedBox(),
            error:   (e, _) => const SizedBox(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEtapeForm(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle étape'),
      ),
      body: etapes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Erreur : $e')),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.layers_outlined,
                      size: 64, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  const Text('Aucune étape pour ce projet',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text('Commencez par créer une étape',
                      style: TextStyle(color: AppColors.textMuted)),
                  const SizedBox(height: 20),

                  // Bouton cloner
                  OutlinedButton.icon(
                    onPressed: () => _showClonerDialog(context),
                    icon: const Icon(Icons.copy_outlined),
                    label: const Text('Cloner depuis un projet'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(etapesNotifierProvider(widget.projectId)),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                // Bouton cloner en haut
                OutlinedButton.icon(
                  onPressed: () => _showClonerDialog(context),
                  icon: const Icon(Icons.copy_outlined, size: 18),
                  label: const Text('Cloner étapes depuis un autre projet'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                  ),
                ),
                const SizedBox(height: 16),

                // Liste des étapes
                ...list.map((etape) => _EtapeCard(
                  etape: etape,
                  projectId: widget.projectId,
                  onDelete: () => ref
                      .read(etapesNotifierProvider(widget.projectId).notifier)
                      .deleteEtape(etape.id),
                )),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Formulaire nouvelle étape ──
  void _showEtapeForm(BuildContext context) {
    final nomCtrl  = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Nouvelle étape',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                TextField(
                  controller: nomCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Nom de l\'étape *',
                    prefixIcon: Icon(Icons.layers_outlined),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description (optionnel)',
                    prefixIcon: Icon(Icons.notes_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),

                // Dates
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final d = await showDatePicker(
                            context: ctx,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (d != null) setModal(() => startDate = d);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Début',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          child: Text(
                            startDate != null
                                ? '${startDate!.day}/${startDate!.month}/${startDate!.year}'
                                : 'Choisir',
                            style: TextStyle(
                                color: startDate != null
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final d = await showDatePicker(
                            context: ctx,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (d != null) setModal(() => endDate = d);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Fin',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          child: Text(
                            endDate != null
                                ? '${endDate!.day}/${endDate!.month}/${endDate!.year}'
                                : 'Choisir',
                            style: TextStyle(
                                color: endDate != null
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () async {
                    if (nomCtrl.text.trim().isEmpty) return;
                    await ref
                        .read(etapesNotifierProvider(widget.projectId)
                            .notifier)
                        .createEtape(
                          nom:         nomCtrl.text.trim(),
                          description: descCtrl.text.trim().isEmpty
                              ? null : descCtrl.text.trim(),
                          startDate:   startDate
                              ?.toIso8601String().split('T').first,
                          endDate:     endDate
                              ?.toIso8601String().split('T').first,
                        );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Créer l\'étape'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Dialog cloner ──
  void _showClonerDialog(BuildContext context) {
    final projects = ref.read(projectsNotifierProvider).valueOrNull ?? [];
    final autresProjets = projects
        .where((p) => p.id != widget.projectId)
        .toList();

    if (autresProjets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun autre projet disponible pour cloner'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cloner les étapes',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choisissez le projet dont vous voulez copier les étapes :',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 12),
            ...autresProjets.map((p) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.folder_outlined,
                  color: AppColors.primary),
              title: Text(p.name,
                  style: const TextStyle(fontSize: 14)),
              subtitle: Text('${p.progress}% complété',
                  style: const TextStyle(fontSize: 12)),
              onTap: () async {
                Navigator.pop(ctx);
                await ref
                    .read(etapesNotifierProvider(widget.projectId).notifier)
                    .clonerDepuis(p.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Étapes de "${p.name}" clonées avec succès'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteProject(
      BuildContext context, WidgetRef ref, String projectName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le projet'),
        content: Text(
            'Voulez-vous vraiment supprimer "$projectName" ?\n\nToutes les étapes et tâches seront supprimées.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(projectsNotifierProvider.notifier)
        .deleteProject(widget.projectId);
    if (mounted) Navigator.pop(context);
  }
}

// ── Card Étape ──
class _EtapeCard extends ConsumerWidget {
  final EtapeModel etape;
  final String projectId;
  final VoidCallback onDelete;

  const _EtapeCard({
    required this.etape,
    required this.projectId,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksByEtapeProvider(etape.id));
    final statutColor = switch (etape.statut) {
      'en_cours' => AppColors.accent,
      'termine'  => AppColors.success,
      _          => AppColors.textMuted,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Theme(
        data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),

          // En-tête étape
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: statutColor.withOpacity(0.15),
            child: Text('${etape.ordre}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statutColor)),
          ),
          title: Text(etape.nom,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 15)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (etape.description != null) ...[
                const SizedBox(height: 2),
                Text(etape.description!,
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 4),
              Row(
                children: [
                  // Badge statut
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statutColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(etape.statutLabel,
                        style: TextStyle(
                            fontSize: 11,
                            color: statutColor,
                            fontWeight: FontWeight.w600)),
                  ),
                  if (etape.endDate != null) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.calendar_today_outlined,
                        size: 11, color: AppColors.textMuted),
                    const SizedBox(width: 3),
                    Text(
                      '${etape.endDate!.day}/${etape.endDate!.month}/${etape.endDate!.year}',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ],
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Changer statut
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert,
                    color: AppColors.textMuted),
                onSelected: (value) async {
                  if (value == 'delete') {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Supprimer l\'étape'),
                        content: Text(
                            'Supprimer "${etape.nom}" et toutes ses tâches ?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Annuler'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Supprimer'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) onDelete();
                  } else {
                    await ref
                        .read(etapesNotifierProvider(projectId).notifier)
                        .updateStatut(etape.id, value);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'a_faire',
                      child: Text('Marquer À faire')),
                  const PopupMenuItem(
                      value: 'en_cours',
                      child: Text('Marquer En cours')),
                  const PopupMenuItem(
                      value: 'termine',
                      child: Text('Marquer Terminée')),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Supprimer',
                        style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            ],
          ),

          // Contenu déplié : tâches de l'étape
          children: [
            tasks.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(8),
                child: LinearProgressIndicator(),
              ),
              error: (e, _) => Text('Erreur : $e'),
              data: (taskList) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Liste des tâches
                  if (taskList.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('Aucune tâche dans cette étape',
                          style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13)),
                    )
                  else
                    ...taskList.map((t) => _TaskRow(
                      task: t,
                      projectId: projectId,
                    )),

                  // Bouton ajouter tâche
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () =>
                        _showTaskForm(context, ref, etape),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Ajouter une tâche',
                        style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(
                          color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(
                          vertical: 8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTaskForm(
      BuildContext context, WidgetRef ref, EtapeModel etape) {
    final titleCtrl = TextEditingController();
    final descCtrl  = TextEditingController();
    String priority      = 'moyenne';
    String? assigneeId;
    DateTime? dueDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          final users =
              ref.watch(allUsersProvider).valueOrNull ?? [];
          return Padding(
            padding: EdgeInsets.fromLTRB(
                20, 20, 20,
                MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.layers_outlined,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Nouvelle tâche — ${etape.nom}',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: titleCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Titre *',
                      prefixIcon: Icon(Icons.task_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description (optionnel)',
                      prefixIcon: Icon(Icons.notes_outlined),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: priority,
                    decoration: const InputDecoration(
                      labelText: 'Priorité',
                      prefixIcon: Icon(Icons.flag_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'faible', child: Text('Faible')),
                      DropdownMenuItem(
                          value: 'moyenne', child: Text('Moyenne')),
                      DropdownMenuItem(
                          value: 'elevee', child: Text('Élevée')),
                    ],
                    onChanged: (v) => setModal(() => priority = v!),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String?>(
                    value: assigneeId,
                    decoration: const InputDecoration(
                      labelText: 'Assigner à (optionnel)',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('— Non assigné —',
                            style: TextStyle(
                                color: AppColors.textMuted)),
                      ),
                      ...users.map((u) => DropdownMenuItem(
                        value: u.id,
                        child: Text(u.fullName),
                      )),
                    ],
                    onChanged: (v) =>
                        setModal(() => assigneeId = v),
                  ),
                  const SizedBox(height: 12),

                  InkWell(
                    onTap: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (d != null) setModal(() => dueDate = d);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date limite (optionnel)',
                        prefixIcon:
                            Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(
                        dueDate != null
                            ? '${dueDate!.day}/${dueDate!.month}/${dueDate!.year}'
                            : 'Choisir une date',
                        style: TextStyle(
                            color: dueDate != null
                                ? AppColors.textPrimary
                                : AppColors.textMuted),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () async {
                      if (titleCtrl.text.trim().isEmpty) return;
                      await ref
                          .read(tasksNotifierProvider(projectId)
                              .notifier)
                          .createTask(
                            title:       titleCtrl.text.trim(),
                            etapeId:     etape.id,
                            description: descCtrl.text.trim().isEmpty
                                ? null : descCtrl.text.trim(),
                            priority:    priority,
                            assigneeId:  assigneeId,
                            dueDate:     dueDate
                                ?.toIso8601String()
                                .split('T')
                                .first,
                          );
                      ref.invalidate(
                          tasksByEtapeProvider(etape.id));
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Créer la tâche'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Ligne tâche dans une étape ──
class _TaskRow extends ConsumerWidget {
  final TaskModel task;
  final String projectId;
  const _TaskRow({required this.task, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priorityColor = switch (task.priority) {
      'elevee'  => AppColors.error,
      'moyenne' => AppColors.warning,
      _         => AppColors.success,
    };

    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Container(
        width: 8, height: 8,
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          color: priorityColor,
          shape: BoxShape.circle,
        ),
      ),
      title: Text(
        task.title,
        style: TextStyle(
          fontSize: 13,
          decoration: task.status == 'termine'
              ? TextDecoration.lineThrough : null,
          color: task.status == 'termine'
              ? AppColors.textMuted : AppColors.textPrimary,
        ),
      ),
      subtitle: task.dueDate != null
          ? Text(
              '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}',
              style: TextStyle(
                  fontSize: 11,
                  color: task.isLate
                      ? AppColors.error : AppColors.textMuted),
            )
          : null,
      trailing: const Icon(Icons.chevron_right,
          size: 16, color: AppColors.textMuted),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TaskDetailScreen(
            task: task,
            projectId: projectId,
          ),
        ),
      ),
    );
  }
}