class EtapeModel {
  final String id;
  final String projectId;
  final String nom;
  final String? description;
  final int ordre;
  final String statut;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;

  const EtapeModel({
    required this.id,
    required this.projectId,
    required this.nom,
    this.description,
    required this.ordre,
    required this.statut,
    this.startDate,
    this.endDate,
    required this.createdAt,
  });

  factory EtapeModel.fromJson(Map<String, dynamic> json) => EtapeModel(
    id:          json['id'],
    projectId:   json['project_id'],
    nom:         json['nom'],
    description: json['description'],
    ordre:       json['ordre'] ?? 1,
    statut:      json['statut'] ?? 'a_faire',
    startDate:   json['start_date'] != null
        ? DateTime.parse(json['start_date']) : null,
    endDate:     json['end_date'] != null
        ? DateTime.parse(json['end_date']) : null,
    createdAt:   DateTime.parse(json['created_at']),
  );

  bool get isEnCours => statut == 'en_cours';
  bool get isTermine => statut == 'termine';

  String get statutLabel => switch (statut) {
    'en_cours' => 'En cours',
    'termine'  => 'Terminée',
    _          => 'À faire',
  };
}