import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  // Credentials
  static const String _url =  String.fromEnvironment('SUPABASE_URL');
  static const String _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Initializes the Supabase connection
  static Future<void> initialize() async {
    await Supabase.initialize(url: _url, publishableKey: _anonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;
}
