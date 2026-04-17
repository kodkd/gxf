class ProjectModel {
  final String id;
  final String name;
  final String? description;
  final String ownerId;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final int progress;
  final DateTime createdAt;

  const ProjectModel({
    required this.id,
    required this.name,
    this.description,
    required this.ownerId,
    required this.status,
    this.startDate,
    this.endDate,
    required this.progress,
    required this.createdAt,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) => ProjectModel(
    id:          json['id'],
    name:        json['name'],
    description: json['description'],
    ownerId:     json['owner_id'],
    status:      json['status'],
    startDate:   json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
    endDate:     json['end_date']   != null ? DateTime.parse(json['end_date'])   : null,
    progress:    json['progress'] ?? 0,
    createdAt:   DateTime.parse(json['created_at']),
  );

  bool get isEnCours  => status == 'en_cours';
  bool get isTermine  => status == 'termine';
  bool get isSuspendu => status == 'suspendu';
}