import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  // Credentials
  static const String _url = 'https://ikqltuhipjaqscwcmxgz.supabase.co';
  static const String _anonKey =
      'sb_publishable_YDhsllUvnfqFNsOgeDFiNA_FHPEoXc7';

  /// Initializes the Supabase connection
  static Future<void> initialize() async {
    await Supabase.initialize(url: _url, publishableKey: _anonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;
}
