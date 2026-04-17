import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/constants/env.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: Env.supabaseUrl, // remplacez ici
    anonKey: Env.supabaseAnonKey, // remplacez ici
    authOptions: FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
  );

  runApp(const ProviderScope(child: GxfApp()));
}

// Raccourci pratique pour accéder à Supabase partout
final supabase = Supabase.instance.client;
