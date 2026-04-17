class ChecklistItem {
  final String label;
  final bool done;

  const ChecklistItem({required this.label, required this.done});

  factory ChecklistItem.fromJson(Map<String, dynamic> j) =>
      ChecklistItem(label: j['label'], done: j['done'] ?? false);

  Map<String, dynamic> toJson() => {'label': label, 'done': done};
}

class TaskModel {
  final String id;
  final String projectId;
  final String? etapeId;
  final String? assigneeId;
  final String title;
  final String? description;
  final String status;
  final String priority;
  final DateTime? dueDate;
  final List<String> tags;
  final List<ChecklistItem> checklist;
  final DateTime createdAt;

  const TaskModel({
    required this.id,
    required this.projectId,
    this.etapeId,
    this.assigneeId,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.dueDate,
    required this.tags,
    required this.checklist,
    required this.createdAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
    id:          json['id'],
    projectId:   json['project_id'],
    etapeId:     json['etape_id'], 
    assigneeId:  json['assignee_id'],
    title:       json['title'],
    description: json['description'],
    status:      json['status'],
    priority:    json['priority'],
    dueDate:     json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
    tags:        List<String>.from(json['tags'] ?? []),
    checklist:   (json['checklist'] as List<dynamic>? ?? [])
                   .map((e) => ChecklistItem.fromJson(e)).toList(),
    createdAt:   DateTime.parse(json['created_at']),
  );

  bool get isLate => dueDate != null &&
      dueDate!.isBefore(DateTime.now()) && status != 'termine';

  int get checklistDone => checklist.where((c) => c.done).length;
}