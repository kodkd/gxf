import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gxf/services/notification_banner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../providers/notification_provider.dart';
import '../providers/task_provider.dart';
import '../providers/project_provider.dart';
import 'package:flutter/material.dart';

final _navigatorKeyProvider = Provider<GlobalKey<NavigatorState>>((ref) {
  return GlobalKey<NavigatorState>();
});

final navigatorKeyProvider = _navigatorKeyProvider;
class RealtimeService {
  final Ref _ref;
  RealtimeChannel? _notifChannel;
  RealtimeChannel? _taskChannel;

  RealtimeService(this._ref);

  void initialize() {
    _listenNotifications();
    _listenTasks();
  }

  // Écoute les nouvelles notifications en temps réel
void _listenNotifications() {
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return;

  _notifChannel = supabase
      .channel('notifications:$userId')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (payload) {
          _ref.invalidate(notificationsProvider);

          // Afficher la bannière si contexte disponible
          final context = _ref.read(_navigatorKeyProvider)
              .currentContext;
          if (context != null && context.mounted) {
            final title = payload.newRecord['title'] as String? ?? 'Notification';
            final body  = payload.newRecord['body']  as String? ?? '';
            NotificationBanner.show(
              context,
              title: title,
              body:  body,
              icon:  Icons.task_alt,
            );
          }
        },
      )
      .subscribe();
}

  // Écoute les nouvelles tâches en temps réel
  void _listenTasks() {
    _taskChannel = supabase
        .channel('tasks_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'tasks',
          callback: (payload) {
            // Rafraîchir les tâches et projets
            _ref.invalidate(allTasksProvider);
            _ref.invalidate(projectsNotifierProvider);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'tasks',
          callback: (payload) {
            _ref.invalidate(allTasksProvider);
            _ref.invalidate(projectsNotifierProvider);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'tasks',
          callback: (payload) {
            _ref.invalidate(allTasksProvider);
            _ref.invalidate(projectsNotifierProvider);
          },
        )
        .subscribe();
  }

  void dispose() {
    _notifChannel?.unsubscribe();
    _taskChannel?.unsubscribe();
  }
}

// Provider du service
final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final service = RealtimeService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});