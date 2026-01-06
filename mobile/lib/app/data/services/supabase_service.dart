  import 'package:get/get.dart';
  import 'package:supabase_flutter/supabase_flutter.dart';
  import 'package:flutter_dotenv/flutter_dotenv.dart';
  import 'package:flutter/foundation.dart';

  class SupabaseService extends GetxService {
    late final SupabaseClient client;

    Future<SupabaseService> init() async {
      try {
        if (kDebugMode) {
          debugPrint('Loading .env file...');
        }

        await dotenv.load(fileName: "assets/env/.env");

        final supabaseUrl = dotenv.env['SUPABASE_URL'];
        final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

        if (supabaseUrl == null || supabaseAnonKey == null) {
          throw Exception(
            'Supabase URL or Anon Key is not set in the environment variables.',
          );
        }

        await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

        client = Supabase.instance.client;

        if (kDebugMode) {
          debugPrint('Suapabse initialized with URL: $supabaseUrl');
        }

        return this;
      } catch (e) {
        debugPrint('error initializing supabase: $e');
        rethrow;
      }
    }

    //Auth helpers
    User? get currentUser => client.auth.currentUser;
    Session? get currentSession => client.auth.currentSession;
    Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

    //Database helpers
    SupabaseQueryBuilder from(String table) => client.from(table);
    SupabaseStorageClient get storage => client.storage;
  }
