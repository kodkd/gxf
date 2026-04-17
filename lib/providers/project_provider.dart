import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import '../models/project_model.dart';

final projectsProvider = FutureProvider<List<ProjectModel>>((ref) async {
  final data = await supabase
      .from('projects')
      .select()
      .order('created_at', ascending: false);
  return (data as List).map((e) => ProjectModel.fromJson(e)).toList();
});

final projectDetailProvider =
    FutureProvider.family<ProjectModel, String>((ref, id) async {
  final data = await supabase
      .from('projects')
      .select()
      .eq('id', id)
      .single();
  return ProjectModel.fromJson(data);
});

class ProjectsNotifier extends AsyncNotifier<List<ProjectModel>> {
  @override
  Future<List<ProjectModel>> build() async {
    final data = await supabase
        .from('projects')
        .select()
        .order('created_at', ascending: false);
    return (data as List).map((e) => ProjectModel.fromJson(e)).toList();
  }

Future<void> createProject({
  required String name,
  String? description,
  String? startDate,
  String? endDate,
  String? chefId,        // ← nouveau paramètre
}) async {
  final userId = supabase.auth.currentUser!.id;

  final result = await supabase.from('projects').insert({
    'name':        name,
    'description': description,
    'owner_id':    chefId ?? userId,  // chef choisi ou créateur
    'start_date':  startDate,
    'end_date':    endDate,
  }).select().single();

  // Ajouter le créateur comme membre
  await supabase.from('project_members').insert({
    'project_id': result['id'],
    'user_id':    userId,
  });

  // Si un chef différent est choisi, l'ajouter aussi comme membre
  if (chefId != null && chefId != userId) {
    await supabase.from('project_members').insert({
      'project_id': result['id'],
      'user_id':    chefId,
    });
  }

  ref.invalidateSelf();
}

  Future<void> updateStatus(String projectId, String status) async {
    await supabase
        .from('projects')
        .update({'status': status})
        .eq('id', projectId);
    ref.invalidateSelf();
  }

  Future<void> deleteProject(String projectId) async {
    await supabase.from('projects').delete().eq('id', projectId);
    ref.invalidateSelf();
  }
}

final projectsNotifierProvider =
    AsyncNotifierProvider<ProjectsNotifier, List<ProjectModel>>(
        ProjectsNotifier.new);