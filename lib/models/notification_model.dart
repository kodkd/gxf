class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String? body;
  final String? refId;
  final DateTime? readAt;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.body,
    this.refId,
    this.readAt,
    required this.createdAt,
  });

  bool get isRead => readAt != null;

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id:        json['id'],
        userId:    json['user_id'],
        type:      json['type'],
        title:     json['title'],
        body:      json['body'],
        refId:     json['ref_id'],
        readAt:    json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
        createdAt: DateTime.parse(json['created_at']),
      );
}