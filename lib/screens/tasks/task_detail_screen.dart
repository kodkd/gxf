import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gxf/core/utils/date_utils.dart';
import '../../core/constants/app_colors.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../../providers/comment_provider.dart';
import '../../main.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final TaskModel task;
  final String projectId;

  const TaskDetailScreen({
    super.key,
    required this.task,
    required this.projectId,
  });

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  final _commentCtrl = TextEditingController();
  bool _sendingComment = false;
  late TaskModel _task;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmDeleteTask(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Supprimer la tâche'),
      content: Text(
          'Voulez-vous vraiment supprimer "${_task.title}" ? Cette action est irréversible.'),
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
      .read(tasksNotifierProvider(widget.projectId).notifier)
      .deleteTask(_task.id);

  if (mounted) Navigator.pop(context);
}

  Future<void> _toggleChecklistItem(int index) async {
    final updated = List<ChecklistItem>.from(_task.checklist);
    updated[index] = ChecklistItem(
      label: updated[index].label,
      done: !updated[index].done,
    );
    final newChecklist = updated.map((e) => e.toJson()).toList();
    await supabase
        .from('tasks')
        .update({'checklist': newChecklist})
        .eq('id', _task.id);
    setState(() {
      _task = TaskModel(
        id:          _task.id,
        projectId:   _task.projectId,
        assigneeId:  _task.assigneeId,
        title:       _task.title,
        description: _task.description,
        status:      _task.status,
        priority:    _task.priority,
        dueDate:     _task.dueDate,
        tags:        _task.tags,
        checklist:   updated,
        createdAt:   _task.createdAt,
      );
    });
    ref.invalidate(tasksNotifierProvider(widget.projectId));
  }

  Future<void> _sendComment() async {
    if (_commentCtrl.text.trim().isEmpty) return;
    setState(() => _sendingComment = true);
    try {
      await ref
          .read(commentsProvider(_task.id).notifier)
          .addComment(_commentCtrl.text.trim());
      _commentCtrl.clear();
    } finally {
      if (mounted) setState(() => _sendingComment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final comments = ref.watch(commentsProvider(_task.id));
    final priorityColor = switch (_task.priority) {
      'elevee'  => AppColors.error,
      'moyenne' => AppColors.warning,
      _         => AppColors.success,
    };
    final priorityLabel = switch (_task.priority) {
      'elevee'  => 'Élevée',
      'moyenne' => 'Moyenne',
      _         => 'Faible',
    };

    return Scaffold(
      appBar: AppBar(
  title: const Text('Détail tâche',
      style: TextStyle(fontWeight: FontWeight.bold)),
  actions: [
    IconButton(
      icon: const Icon(Icons.delete_outline, color: AppColors.error),
      onPressed: () => _confirmDeleteTask(context, ref),
    ),
  ],
),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── Titre + priorité ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(_task.title,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(priorityLabel,
                    style: TextStyle(
                        fontSize: 12,
                        color: priorityColor,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),

          // ── Statut ──
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Statut : ',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              DropdownButton<String>(
                value: _task.status,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'a_faire',  child: Text('À faire')),
                  DropdownMenuItem(value: 'en_cours', child: Text('En cours')),
                  DropdownMenuItem(value: 'termine',  child: Text('Terminé')),
                ],
                onChanged: (v) async {
                  if (v == null) return;
                  await ref
                      .read(tasksNotifierProvider(widget.projectId).notifier)
                      .updateStatus(_task.id, v);
                  setState(() => _task = TaskModel(
                    id: _task.id, projectId: _task.projectId,
                    assigneeId: _task.assigneeId, title: _task.title,
                    description: _task.description, status: v,
                    priority: _task.priority, dueDate: _task.dueDate,
                    tags: _task.tags, checklist: _task.checklist,
                    createdAt: _task.createdAt,
                  ));
                },
              ),
            ],
          ),

          // ── Description ──
          if (_task.description != null) ...[
            const Divider(height: 24),
            const Text('Description',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 6),
            Text(_task.description!,
                style: TextStyle(color: AppColors.textMuted, height: 1.5)),
          ],

          // ── Date limite ──
          if (_task.dueDate != null) ...[
            const Divider(height: 24),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: _task.isLate ? AppColors.error : AppColors.textMuted,
                ),
                const SizedBox(width: 8),
                Text(
                  'Échéance : ${_task.dueDate!.day}/${_task.dueDate!.month}/${_task.dueDate!.year}',
                  style: TextStyle(
                    color: _task.isLate ? AppColors.error : AppColors.textMuted,
                    fontWeight: _task.isLate ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (_task.isLate) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('En retard',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.error,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ],
            ),
          ],

          // ── Tags ──
          if (_task.tags.isNotEmpty) ...[
            const Divider(height: 24),
            const Text('Étiquettes',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _task.tags
                  .map((tag) => Chip(
                        label: Text(tag,
                            style: const TextStyle(fontSize: 12)),
                        backgroundColor:
                            AppColors.primary.withOpacity(0.1),
                        side: BorderSide.none,
                        padding: EdgeInsets.zero,
                      ))
                  .toList(),
            ),
          ],

          // ── Checklist ──
          if (_task.checklist.isNotEmpty) ...[
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Checklist',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                Text(
                  '${_task.checklistDone}/${_task.checklist.length}',
                  style: TextStyle(
                      color: AppColors.textMuted, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: _task.checklist.isEmpty
                  ? 0
                  : _task.checklistDone / _task.checklist.length,
              backgroundColor: AppColors.border,
              color: AppColors.success,
              borderRadius: BorderRadius.circular(4),
              minHeight: 5,
            ),
            const SizedBox(height: 8),
            ..._task.checklist.asMap().entries.map(
              (entry) => CheckboxListTile(
                value: entry.value.done,
                onChanged: (_) => _toggleChecklistItem(entry.key),
                title: Text(
                  entry.value.label,
                  style: TextStyle(
                    fontSize: 14,
                    decoration: entry.value.done
                        ? TextDecoration.lineThrough
                        : null,
                    color: entry.value.done
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                  ),
                ),
                activeColor: AppColors.success,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
          ],

          // ── Commentaires ──
          const Divider(height: 32),
          const Text('Commentaires',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 12),

          comments.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Erreur: $e'),
            data: (list) => list.isEmpty
                ? Text('Aucun commentaire',
                    style: TextStyle(color: AppColors.textMuted))
                : Column(
                    children: list
                        .map((c) => _CommentTile(comment: c))
                        .toList(),
                  ),
          ),

          // ── Saisie commentaire ──
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Ajouter un commentaire...',
                    isDense: true,
                  ),
                  onSubmitted: (_) => _sendComment(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _sendingComment ? null : _sendComment,
                icon: _sendingComment
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send_rounded),
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final comment;
  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    final initials = (comment.userFullName ?? 'U')
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary.withOpacity(0.15),
            child: Text(initials,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(comment.userFullName ?? 'Utilisateur',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(width: 8),
                    Text(
                      AppDateUtils.formatRelative(comment.createdAt),
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(comment.content,
                    style: const TextStyle(fontSize: 14, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}