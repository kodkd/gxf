import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../models/user_model.dart';

final sessionProvider = StreamProvider<Session?>((ref) {
  return supabase.auth.onAuthStateChange.map((e) => e.session);
});

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final session = supabase.auth.currentSession;
  if (session == null) return null;
  final data = await supabase
      .from('profiles')
      .select()
      .eq('id', session.user.id)
      .single();
  return UserModel.fromJson(data);
});

final allUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  final data = await supabase
      .from('profiles')
      .select()
      .eq('is_active', true)
      .order('full_name');
  return (data as List).map((e) => UserModel.fromJson(e)).toList();
});

class AuthNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    final session = supabase.auth.currentSession;
    if (session == null) return null;
    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', session.user.id)
        .single();
    return UserModel.fromJson(data);
  }

  // Connexion email OU username
  Future<void> signIn(String login, String password) async {
    String email = login.trim();

    // Si ce n'est pas un email, chercher par username
    if (!login.contains('@')) {
      final data = await supabase
          .from('profiles')
          .select('email')
          .eq('username', login.trim())
          .maybeSingle();

      if (data == null) {
        throw Exception('Nom d\'utilisateur introuvable');
      }
      email = data['email'];
    }

    await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    ref.invalidateSelf();
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
    state = const AsyncData(null);
  }

  Future<void> updatePassword(String newPassword) async {
    await supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  // Mettre à jour profil (nom + username)
  Future<void> updateProfile({
    required String fullName,
    String? username,
  }) async {
    final userId = supabase.auth.currentUser!.id;

    // Vérifier unicité du username
    if (username != null && username.isNotEmpty) {
      final existing = await supabase
          .from('profiles')
          .select('id')
          .eq('username', username)
          .neq('id', userId)
          .maybeSingle();

      if (existing != null) {
        throw Exception('Ce nom d\'utilisateur est déjà pris');
      }
    }

    await supabase.from('profiles').update({
      'full_name': fullName,
      'username':  username?.isEmpty == true ? null : username,
    }).eq('id', userId);

    ref.invalidateSelf();
  }

  // Uploader photo de profil
  Future<void> updateAvatar(String filePath) async {
    final userId   = supabase.auth.currentUser!.id;
    final fileName = '$userId/avatar.jpg';

    await supabase.storage.from('avatars').upload(
      fileName,
      filePath as dynamic,
      fileOptions: const FileOptions(upsert: true),
    );

    final url = supabase.storage
        .from('avatars')
        .getPublicUrl(fileName);

    // Ajouter timestamp pour forcer le rechargement du cache
    final avatarUrl = '$url?t=${DateTime.now().millisecondsSinceEpoch}';

    await supabase.from('profiles').update({
      'avatar_url': avatarUrl,
    }).eq('id', userId);

    ref.invalidateSelf();
  }
}

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(
  AuthNotifier.new,
);