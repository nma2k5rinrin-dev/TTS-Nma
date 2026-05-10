import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  }

  // Auth shortcuts
  static GoTrueClient get auth => client.auth;
  static User? get currentUser => client.auth.currentUser;
  static bool get isAuthenticated => currentUser != null;

  // Database shortcuts
  static SupabaseQueryBuilder table(String name) => client.from(name);

  // Storage shortcuts
  static SupabaseStorageClient get storage => client.storage;

  // Functions shortcuts
  static FunctionsClient get functions => client.functions;
}
