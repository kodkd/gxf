class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String? avatarUrl;
  final String? username;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.username,
    this.isActive = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id:        json['id'],
    fullName:  json['full_name'],
    email:     json['email'],
    role:      json['role'],
    avatarUrl: json['avatar_url'],
    username:  json['username'],
    isActive:  json['is_active'] ?? true,
  );

  bool get isAdmin      => role == 'admin';
  bool get isChefProjet => role == 'chef_projet';

  // Affiche username si dispo sinon email
  String get displayLogin => username ?? email;
}