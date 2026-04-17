import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/project_provider.dart';
import '../../providers/task_provider.dart';

class DashboardHome extends ConsumerWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user      = ref.watch(currentUserProvider).valueOrNull;
    final projects  = ref.watch(projectsProvider);
    final tasks     = ref.watch(allTasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bonjour, ${user?.fullName.split(' ').first ?? ''}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Tableau de bord',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          ],
        ),
       
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(projectsProvider);
          ref.invalidate(allTasksProvider);
        },
        child: projects.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur: $e')),
          data: (projectList) => tasks.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur: $e')),
            data: (taskList) {
              final actifs    = projectList.where((p) => p.isEnCours).length;
              final enCours   = taskList.where((t) => t.status == 'en_cours').length;
              final enRetard  = taskList.where((t) => t.isLate).length;
              final terminees = taskList.where((t) => t.status == 'termine').length;
              final total     = taskList.length;
              final perf      = total > 0 ? (terminees * 100 ~/ total) : 0;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // KPI cards
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _KpiCard('Projets actifs',  '$actifs',   Icons.folder_open,      AppColors.primary),
                      _KpiCard('En cours',        '$enCours',  Icons.pending_actions,  AppColors.accent),
                      _KpiCard('En retard',       '$enRetard', Icons.warning_amber,    AppColors.warning),
                      _KpiCard('Performance',     '$perf%',    Icons.trending_up,      AppColors.success),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Tâches en retard
                  if (enRetard > 0) ...[
                    Text('Tâches en retard',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...taskList.where((t) => t.isLate).take(3).map(
                      (t) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.warning_amber,
                              color: AppColors.warning),
                          title: Text(t.title),
                          subtitle: Text(
                            'Échéance: ${t.dueDate!.day}/${t.dueDate!.month}/${t.dueDate!.year}',
                            style: const TextStyle(color: AppColors.warning),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Projets récents
                  Text('Projets récents',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...projectList.take(3).map((p) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(p.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              _StatusBadge(p.status),
                            ],
                          ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: p.progress / 100,
                            backgroundColor: AppColors.border,
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 4),
                          Text('${p.progress}%',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  )),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
          children: [
            Icon(icon, color: color, size: 24),
            const Spacer(),
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
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
      'en_cours':  (AppColors.primary, 'En cours'),
      'termine':   (AppColors.success, 'Terminé'),
      'suspendu':  (AppColors.warning, 'Suspendu'),
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