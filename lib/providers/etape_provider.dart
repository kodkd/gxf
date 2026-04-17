import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import '../models/etape_model.dart';

// Liste des étapes d'un projet
final etapesProvider =
    FutureProvider.family<List<EtapeModel>, String>((ref, projectId) async {
  final data = await supabase
      .from('etapes')
      .select()
      .eq('project_id', projectId)
      .order('ordre', ascending: true);
  return (data as List).map((e) => EtapeModel.fromJson(e)).toList();
});

class EtapesNotifier extends FamilyAsyncNotifier<List<EtapeModel>, String> {
  @override
  Future<List<EtapeModel>> build(String projectId) async {
    final data = await supabase
        .from('etapes')
        .select()
        .eq('project_id', projectId)
        .order('ordre', ascending: true);
    return (data as List).map((e) => EtapeModel.fromJson(e)).toList();
  }

  // Créer une étape
  Future<void> createEtape({
    required String nom,
    String? description,
    String? startDate,
    String? endDate,
  }) async {
    // Calculer le prochain ordre
    final current = state.valueOrNull ?? [];
    final nextOrdre = current.isEmpty
        ? 1
        : current.map((e) => e.ordre).reduce((a, b) => a > b ? a : b) + 1;

    await supabase.from('etapes').insert({
      'project_id':  arg,
      'nom':         nom,
      'description': description,
      'ordre':       nextOrdre,
      'start_date':  startDate,
      'end_date':    endDate,
    });
    ref.invalidateSelf();
  }

  // Mettre à jour le statut
  Future<void> updateStatut(String etapeId, String statut) async {
    await supabase
        .from('etapes')
        .update({'statut': statut})
        .eq('id', etapeId);
    ref.invalidateSelf();
  }

  // Supprimer une étape
  Future<void> deleteEtape(String etapeId) async {
    await supabase.from('etapes').delete().eq('id', etapeId);
    ref.invalidateSelf();
  }

  // Cloner les étapes d'un autre projet
  Future<void> clonerDepuis(String sourceProjectId) async {
    final source = await supabase
        .from('etapes')
        .select()
        .eq('project_id', sourceProjectId)
        .order('ordre', ascending: true);

    final etapesSource = (source as List)
        .map((e) => EtapeModel.fromJson(e))
        .toList();

    if (etapesSource.isEmpty) return;

    // Calculer le prochain ordre dans le projet actuel
    final current = state.valueOrNull ?? [];
    int nextOrdre = current.isEmpty
        ? 1
        : current.map((e) => e.ordre).reduce((a, b) => a > b ? a : b) + 1;

    // Insérer toutes les étapes clonées
    final toInsert = etapesSource.map((e) {
      final row = {
        'project_id':  arg,
        'nom':         e.nom,
        'description': e.description,
        'ordre':       nextOrdre,
      };
      nextOrdre++;
      return row;
    }).toList();

    await supabase.from('etapes').insert(toInsert);
    ref.invalidateSelf();
  }
}

final etapesNotifierProvider =
    AsyncNotifierProviderFamily<EtapesNotifier, List<EtapeModel>, String>(
        EtapesNotifier.new);