import 'package:uuid/uuid.dart';

class WakeDestination {
  const WakeDestination({
    required this.id,
    required this.name,
    this.user_id,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String name;
  final String? user_id;
  final String address;
  final double latitude;
  final double longitude;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'user_id': user_id,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
  };

    Map<String, dynamic> toRename() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory WakeDestination.fromJson(Map<String, dynamic> json) =>
      WakeDestination(
        id: json['id'] as String,
        name: json['name'] as String,
        user_id: json['user_id'] as String?,
        address: json['address'] as String? ?? '',
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      );

  factory WakeDestination.fromSearchResult(
  Map<String, dynamic> json,
) {
  final latitude = double.parse(json['lat'] as String);
  final longitude = double.parse(json['lon'] as String);

  final address =
      json['display_name'] as String? ?? 'Pinned location';

  final shortAddress = address.split(',').take(3).join(',');

  return WakeDestination(
    id: const Uuid().v4(),
    name: shortAddress,
    address: address,
    latitude: latitude,
    longitude: longitude,
  );
}
}
