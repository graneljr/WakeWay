import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wakeway/core/database/supabase_service.dart';
import 'package:wakeway/features/map/models/wake_destination.dart';
import 'package:wakeway/core/database/sqlite_helper.dart';

/// Reads and writes the signed-in user's saved destinations in Supabase.
class DestinationRepository {
  DestinationRepository({SupabaseClient? client})
    : _client = client ?? SupabaseService.client;

  static const _table = 'destinations';
  final SupabaseClient _client;

  Future<List<WakeDestination>> getDestinations() async {
    final userId = _requireUserId();
    final rows = await _client
        .from(_table)
        .select('id, name, address, latitude, longitude, updated_at')
        .eq('user_id', userId)
        .order('updated_at', ascending: false);

    return rows
        .map((row) => WakeDestination.fromJson(row))
        .toList(growable: false);
  }

  Future<void> saveDestination(WakeDestination destination) async {
    final userId = _requireUserId();
    await _client
        .from(_table)
        .upsert(_toRow(destination, userId), onConflict: 'id');
    await SQLiteHelper.instance.insertDestinations(<String, Object?>{
      'id': destination.id,
      'user_id': userId,
      'name': destination.name,
      'address': destination.address,
      'latitude': destination.latitude,
      'longitude': destination.longitude,
      'updated_at': _now(),
    });
  }

  Future<void> importLegacyDestinations(
    Iterable<WakeDestination> destinations,
  ) async {
    final userId = _requireUserId();
    for (final destination in destinations.toList().reversed) {
      await _client
          .from(_table)
          .upsert(
            _toRow(destination, userId),
            onConflict: 'id',
            ignoreDuplicates: true,
          );
    }
  }

  Future<void> renameDestination(
    WakeDestination destination,
    String name,
  ) async {
    final userId = _requireUserId();
    await _client
        .from(_table)
        .update({'name': name.trim(), 'updated_at': _now()})
        .eq('id', destination.id)
        .eq('user_id', userId);
  }

  Future<void> removeDestination(WakeDestination destination) async {
    final userId = _requireUserId();
    await _client
        .from(_table)
        .delete()
        .eq('id', destination.id)
        .eq('user_id', userId);
  }

  Map<String, Object?> _toRow(WakeDestination destination, String userId) => {
    'id': destination.id,
    'user_id': userId,
    'name': destination.name,
    'address': destination.address,
    'latitude': destination.latitude,
    'longitude': destination.longitude,
    'updated_at': _now(),
  };

  String _now() => DateTime.now().toUtc().toIso8601String();

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Sign in to manage saved destinations.');
    }
    return userId;
  }
}
