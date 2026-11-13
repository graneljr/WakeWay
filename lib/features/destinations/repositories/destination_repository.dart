import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wakeway/core/database/supabase_service.dart';
import 'package:wakeway/features/auth/repositories/authentication_repository.dart';
import 'package:wakeway/features/map/models/wake_destination.dart';
import 'package:wakeway/core/database/sqlite_helper.dart';

/// Reads and writes the signed-in user's saved destinations in Supabase.
class DestinationRepository {
  DestinationRepository({
    SupabaseClient? client,
    AuthenticationRepository? authenticationRepository,
  }) : _client = client ?? SupabaseService.client,
       _authenticationRepository =
           authenticationRepository ??
           AuthenticationRepository(client: client ?? SupabaseService.client);

  static const _table = 'destinations';
  final SupabaseClient _client;
  final AuthenticationRepository _authenticationRepository;

  Future<List<WakeDestination>> getDestinations() async {
    final userId = requireUserId();
    // final userId = _requireUserId();
    // final rows = await _client
    //     .from(_table)
    //     .select('id, name, address, latitude, longitude, updated_at')
    //     .eq('user_id', userId)
    //     .order('updated_at', ascending: false);

    final rows = await SQLiteHelper.instance.getDestinations(userId);
    return rows
        .map((row) => WakeDestination.fromJson(row))
        .toList(growable: false);
  }

  Future<void> saveDestination(WakeDestination destination) async {
    final userId = requireUserId();
    final row = _toRow(destination, userId);
    await SQLiteHelper.instance.insertDestinations({
      ...row,
      'sync_status': 'pending',
    });

    try {
      await _client.from(_table).upsert({
        ...row,
        'deleted_at': null,
      }, onConflict: 'id');
      await SQLiteHelper.instance.markDestinationSynced(destination.id, userId);
    } on Object {
      // Keep the local record available; the sync action can retry the upload.
    }
  }

  Future<void> importLegacyDestinations(
    Iterable<WakeDestination> destinations,
  ) async {
    for (final destination in destinations.toList().reversed) {
      await saveDestination(destination);
    }
  }

  Future<void> renameDestination(
    WakeDestination destination,
    String name,
  ) async {
    final userId = requireUserId();
    final updatedAt = _now();
    await SQLiteHelper.instance.updateDestination(
      destination.id,
      name,
      userId,
      updatedAt: updatedAt,
    );

    try {
      await _client.from(_table).upsert({
        ..._toRow(destination, userId),
        'name': name.trim(),
        'updated_at': updatedAt,
        'deleted_at': null,
      }, onConflict: 'id');
      await SQLiteHelper.instance.markDestinationSynced(destination.id, userId);
    } on Object {
      // The local rename remains authoritative until the next successful sync.
    }
  }

  Future<void> removeDestination(WakeDestination destination) async {
    final userId = requireUserId();
    await SQLiteHelper.instance.deleteDestination(destination, userId);

    final deletedAt = _now();
    try {
      await _client
          .from(_table)
          .update({'deleted_at': deletedAt, 'updated_at': deletedAt})
          .eq('id', destination.id)
          .eq('user_id', userId);
    } on Object {
      // The queued delete will be retried when the device is online.
    }
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

  String requireUserId() {
    try {
      return _authenticationRepository.requireCurrentUserId();
    } on StateError {
      throw StateError('Sign in to manage saved destinations.');
    }
  }
}
