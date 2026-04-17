import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/project_provider.dart';
import '../../models/project_model.dart';
import 'project_detail_screen.dart';
import 'project_form_screen.dart';

class ProjectsListScreen extends ConsumerStatefulWidget {
  const ProjectsListScreen({super.key});

  @override
  ConsumerState<ProjectsListScreen> createState() => _ProjectsListScreenState();
}

class _ProjectsListScreenState extends ConsumerState<ProjectsListScreen> {
  String _filter = 'tous';

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projets',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ProjectFormScreen())),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau projet'),
      ),
      body: Column(
        children: [
          // Filtres
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['tous', 'en_cours', 'suspendu', 'termine']
                    .map((f) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(_filterLabel(f)),
                            selected: _filter == f,
                            onSelected: (_) => setState(() => _filter = f),
                            selectedColor: AppColors.primary.withOpacity(0.15),
                            checkmarkColor: AppColors.primary,
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Liste
          Expanded(
            child: projects.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
              data: (list) {
                final filtered = _filter == 'tous'
                    ? list
                    : list.where((p) => p.status == _filter).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.folder_open,
                            size: 64, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text('Aucun projet',
                            style: TextStyle(color: AppColors.textMuted)),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(projectsNotifierProvider),
                  child: ListView.builder(
  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
  itemCount: filtered.length,
  itemBuilder: (_, i) => Dismissible(
    key: Key(filtered[i].id),
    direction: DismissDirection.endToStart,
    confirmDismiss: (_) async {
      return await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Supprimer le projet'),
          content: Text(
              'Supprimer "${filtered[i].name}" et toutes ses tâches ?'),
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
    },
    onDismissed: (_) => ref
        .read(projectsNotifierProvider.notifier)
        .deleteProject(filtered[i].id),
    background: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_outline, color: Colors.white, size: 26),
          SizedBox(height: 4),
          Text('Supprimer',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    ),
    child: _ProjectCard(filtered[i]),
  ),
),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _filterLabel(String f) => switch (f) {
    'tous'     => 'Tous',
    'en_cours' => 'En cours',
    'suspendu' => 'Suspendu',
    'termine'  => 'Terminé',
    _          => f,
  };
}

class _ProjectCard extends ConsumerWidget {
  final ProjectModel project;
  const _ProjectCard(this.project);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ProjectDetailScreen(projectId: project.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(project.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16)),
                  ),
                  _StatusBadge(project.status),
                ],
              ),
              if (project.description != null) ...[
                const SizedBox(height: 6),
                Text(project.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 13)),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: project.progress / 100,
                      backgroundColor: AppColors.border,
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('${project.progress}%',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              if (project.endDate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      'Échéance : ${project.endDate!.day}/${project.endDate!.month}/${project.endDate!.year}',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final map = {
      'en_cours': (AppColors.primary, 'En cours'),
      'termine':  (AppColors.success, 'Terminé'),
      'suspendu': (AppColors.warning, 'Suspendu'),
    };
    final (color, label) = map[status] ?? (AppColors.textMuted, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.w600)),
    );
  }
}