class CommentModel {
  final String id;
  final String taskId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final String? userFullName;

  const CommentModel({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.userFullName,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) => CommentModel(
    id:           json['id'],
    taskId:       json['task_id'],
    userId:       json['user_id'],
    content:      json['content'],
    createdAt:    DateTime.parse(json['created_at']),
    userFullName: json['profiles']?['full_name'],
  );
}