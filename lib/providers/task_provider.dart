import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import '../models/task_model.dart';

final allTasksProvider = FutureProvider<List<TaskModel>>((ref) async {
  final data = await supabase
      .from('tasks')
      .select()
      .order('created_at', ascending: false);
  return (data as List).map((e) => TaskModel.fromJson(e)).toList();
});

final tasksByProjectProvider =
    FutureProvider.family<List<TaskModel>, String>((ref, projectId) async {
  final data = await supabase
      .from('tasks')
      .select()
      .eq('project_id', projectId)
      .order('created_at', ascending: false);
  return (data as List).map((e) => TaskModel.fromJson(e)).toList();
});

class TasksNotifier extends FamilyAsyncNotifier<List<TaskModel>, String> {
  @override
  Future<List<TaskModel>> build(String projectId) async {
    final data = await supabase
        .from('tasks')
        .select()
        .eq('project_id', projectId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => TaskModel.fromJson(e)).toList();
  }

  Future<void> createTask({
    required String title,
    required String etapeId,
    String? description,
    String? assigneeId,
    String priority = 'moyenne',
    String? dueDate,
  }) async {
    await supabase.from('tasks').insert({
      'project_id':   arg,
      'etape_id':    etapeId,
      'title':        title,
      'description':  description,
      'assignee_id':  assigneeId,
      'priority':     priority,
      'due_date':     dueDate,
    });
    ref.invalidateSelf();
  }

  Future<void> updateStatus(String taskId, String newStatus) async {
    await supabase
        .from('tasks')
        .update({'status': newStatus})
        .eq('id', taskId);
    ref.invalidateSelf();
  }

  Future<void> deleteTask(String taskId) async {
    await supabase.from('tasks').delete().eq('id', taskId);
    ref.invalidateSelf();
  }
}

final tasksNotifierProvider =
    AsyncNotifierProviderFamily<TasksNotifier, List<TaskModel>, String>(
        TasksNotifier.new);

final tasksByEtapeProvider =
    FutureProvider.family<List<TaskModel>, String>((ref, etapeId) async {
  final data = await supabase
      .from('tasks')
      .select()
      .eq('etape_id', etapeId)
      .order('created_at', ascending: false);
  return (data as List).map((e) => TaskModel.fromJson(e)).toList();
});