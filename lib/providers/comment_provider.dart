import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import '../models/comment_model.dart';

class CommentsNotifier extends FamilyAsyncNotifier<List<CommentModel>, String> {
  @override
  Future<List<CommentModel>> build(String taskId) async {
    final data = await supabase
        .from('comments')
        .select('*, profiles(full_name)')
        .eq('task_id', taskId)
        .order('created_at', ascending: true);
    return (data as List).map((e) => CommentModel.fromJson(e)).toList();
  }

  Future<void> addComment(String content) async {
    final userId = supabase.auth.currentUser!.id;
    await supabase.from('comments').insert({
      'task_id': arg,
      'user_id': userId,
      'content': content,
    });
    ref.invalidateSelf();
  }
}

final commentsProvider =
    AsyncNotifierProviderFamily<CommentsNotifier, List<CommentModel>, String>(
        CommentsNotifier.new);