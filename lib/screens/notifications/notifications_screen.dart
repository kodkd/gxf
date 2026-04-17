import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () => ref
                .read(notificationsProvider.notifier)
                .markAllAsRead(),
            child: const Text('Tout lire'),
          ),
        ],
      ),
      body: notifications.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none,
                      size: 64, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  Text('Aucune notification',
                      style: TextStyle(color: AppColors.textMuted)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(notificationsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: list.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (_, i) {
                final n = list[i];
                return ListTile(
                  onTap: () => ref
                      .read(notificationsProvider.notifier)
                      .markAsRead(n.id),
                  leading: CircleAvatar(
                    backgroundColor: n.isRead
                        ? AppColors.border
                        : AppColors.primary.withOpacity(0.12),
                    child: Icon(
                      _iconForType(n.type),
                      size: 18,
                      color: n.isRead
                          ? AppColors.textMuted
                          : AppColors.primary,
                    ),
                  ),
                  title: Text(n.title,
                      style: TextStyle(
                          fontWeight: n.isRead
                              ? FontWeight.normal
                              : FontWeight.w600,
                          fontSize: 14)),
                  subtitle: n.body != null
                      ? Text(n.body!,
                          style: const TextStyle(fontSize: 12))
                      : null,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${n.createdAt.day}/${n.createdAt.month}',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textMuted),
                      ),
                      if (!n.isRead) ...[
                        const SizedBox(height: 4),
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  IconData _iconForType(String type) => switch (type) {
    'nouvelle_tache'    => Icons.add_task,
    'modification'      => Icons.edit_outlined,
    'retard'            => Icons.warning_amber_outlined,
    'commentaire'       => Icons.chat_bubble_outline,
    _                   => Icons.notifications_outlined,
  };
}