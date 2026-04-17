import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import '../models/notification_model.dart';

class NotificationsNotifier
    extends AsyncNotifier<List<NotificationModel>> {
  @override
  Future<List<NotificationModel>> build() async {
    final userId = supabase.auth.currentUser!.id;
    final data = await supabase
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => NotificationModel.fromJson(e)).toList();
  }

  Future<void> markAsRead(String notificationId) async {
    await supabase
        .from('notifications')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('id', notificationId);
    ref.invalidateSelf();
  }

  Future<void> markAllAsRead() async {
    final userId = supabase.auth.currentUser!.id;
    await supabase
        .from('notifications')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('user_id', userId)
        .isFilter('read_at', null);
    ref.invalidateSelf();
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<NotificationModel>>(
        NotificationsNotifier.new);

final unreadCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(notificationsProvider).valueOrNull ?? [];
  return notifs.where((n) => !n.isRead).length;
});