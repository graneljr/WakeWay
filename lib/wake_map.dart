import 'dart:ui' show Codec, ImmutableBuffer;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'ui.dart';
import 'wakeway_controller.dart';

const _defaultCenter = LatLng(14.5547, 121.0244);
final BuiltInMapCachingProvider _mapTileCache =
    BuiltInMapCachingProvider.getOrCreateInstance(maxCacheSize: 1_000_000_000);

class WakeMapView extends StatefulWidget {
  const WakeMapView({
    super.key,
    this.controller,
    this.destination,
    this.selectedPoint,
    this.alarmRadiusMeters,
    this.height = 400,
    this.onPointSelected,
  });

  final WakeWayController? controller;
  final WakeDestination? destination;
  final LatLng? selectedPoint;
  final int? alarmRadiusMeters;
  final double height;
  final ValueChanged<LatLng>? onPointSelected;

  @override
  State<WakeMapView> createState() => _WakeMapViewState();
}

class _WakeMapViewState extends State<WakeMapView> {
  final MapController _mapController = MapController();
  NetworkTileProvider? _onlineTileProvider;
  bool _mapReady = false;
  bool _lastOfflineMode = false;

  @override
  void initState() {
    super.initState();
    _lastOfflineMode = widget.controller?.offlineMode ?? false;
    if (!_lastOfflineMode) {
      _onlineTileProvider = NetworkTileProvider(cachingProvider: _mapTileCache);
    }
    widget.controller?.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(covariant WakeMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_handleControllerChanged);
      final offlineMode = widget.controller?.offlineMode ?? false;
      if (offlineMode != _lastOfflineMode) {
        _lastOfflineMode = offlineMode;
        _onlineTileProvider = offlineMode
            ? null
            : NetworkTileProvider(cachingProvider: _mapTileCache);
      }
      widget.controller?.addListener(_handleControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_handleControllerChanged);
    super.dispose();
  }

  void _handleControllerChanged() {
    final offlineMode = widget.controller?.offlineMode ?? false;
    if (offlineMode == _lastOfflineMode) return;
    _onlineTileProvider = offlineMode
        ? null
        : NetworkTileProvider(cachingProvider: _mapTileCache);
    _lastOfflineMode = offlineMode;
    if (mounted) setState(() {});
  }

  LatLng get _destinationPoint => widget.destination == null
      ? _defaultCenter
      : LatLng(widget.destination!.latitude, widget.destination!.longitude);

  Position? get _position => widget.controller?.currentPosition;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: widget.height,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              backgroundColor: WakeColors.map,
              initialCenter: _position == null
                  ? (widget.selectedPoint ?? _destinationPoint)
                  : LatLng(_position!.latitude, _position!.longitude),
              initialZoom: 14,
              onMapReady: () => _mapReady = true,
              onTap: widget.onPointSelected == null
                  ? null
                  : (tapPosition, point) => widget.onPointSelected!(point),
            ),
            children: [
              TileLayer(
                key: ValueKey(_lastOfflineMode),
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.wakeway',
                tileProvider: _lastOfflineMode
                    ? _CachedOnlyTileProvider(_mapTileCache)
                    : _onlineTileProvider!,
              ),
              if (widget.selectedPoint != null || widget.destination != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: widget.selectedPoint ?? _destinationPoint,
                      radius: (widget.alarmRadiusMeters ?? 0).toDouble(),
                      useRadiusInMeter: true,
                      color: WakeColors.red.withValues(alpha: .12),
                      borderStrokeWidth: 2,
                      borderColor: WakeColors.red.withValues(alpha: .75),
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (_position != null)
                    Marker(
                      point: LatLng(_position!.latitude, _position!.longitude),
                      width: 34,
                      height: 34,
                      child: const _MapMarker(
                        icon: Icons.my_location_rounded,
                        color: WakeColors.blue,
                      ),
                    ),
                  if (widget.destination != null)
                    Marker(
                      point: _destinationPoint,
                      width: 38,
                      height: 42,
                      child: const _MapMarker(
                        icon: Icons.location_on_rounded,
                        color: WakeColors.green,
                      ),
                    ),
                  if (widget.selectedPoint != null)
                    Marker(
                      point: widget.selectedPoint!,
                      width: 38,
                      height: 42,
                      child: const _MapMarker(
                        icon: Icons.notifications_active_rounded,
                        color: WakeColors.red,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const Positioned(left: 10, bottom: 8, child: _MapAttribution()),
          if (widget.controller != null)
            Positioned(
              right: 11,
              bottom: 43,
              child: FloatingActionButton.small(
                heroTag: null,
                onPressed: _locate,
                backgroundColor: Colors.white,
                foregroundColor: WakeColors.blue,
                child: const Icon(Icons.my_location_rounded),
              ),
            ),
          if (widget.onPointSelected != null)
            const Positioned(
              left: 10,
              top: 10,
              child: _MapHint(label: 'Tap map to place alarm point'),
            ),
          if (widget.controller?.offlineMode == true)
            const Positioned(
              left: 10,
              bottom: 30,
              child: _MapHint(label: 'Offline mode · saved tiles only'),
            ),
        ],
      ),
    ),
  );

  Future<void> _locate() async {
    try {
      final position = await widget.controller!.locateOnce();
      if (_mapReady) {
        _mapController.move(LatLng(position.latitude, position.longitude), 15);
      }
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
        ),
      );
    }
  }
}

class _CachedOnlyTileProvider extends TileProvider {
  _CachedOnlyTileProvider(this.cache);

  final MapCachingProvider cache;

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      _CachedTileImageProvider(
        url: getTileUrl(coordinates, options),
        cache: cache,
      );
}

class _CachedTileImageProvider extends ImageProvider<_CachedTileImageProvider> {
  const _CachedTileImageProvider({required this.url, required this.cache});

  final String url;
  final MapCachingProvider cache;

  @override
  ImageStreamCompleter loadImage(
    _CachedTileImageProvider key,
    ImageDecoderCallback decode,
  ) => MultiFrameImageStreamCompleter(
    codec: _loadImage(key, decode),
    scale: 1,
    debugLabel: key.url,
  );

  Future<Codec> _loadImage(
    _CachedTileImageProvider key,
    ImageDecoderCallback decode,
  ) async {
    final Uint8List bytes;
    try {
      bytes =
          (await key.cache.getTile(key.url))?.bytes ??
          TileProvider.transparentImage;
    } on Object {
      return decode(
        await ImmutableBuffer.fromUint8List(TileProvider.transparentImage),
      );
    }
    return decode(await ImmutableBuffer.fromUint8List(bytes));
  }

  @override
  Future<_CachedTileImageProvider> obtainKey(
    ImageConfiguration configuration,
  ) => SynchronousFuture(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _CachedTileImageProvider &&
          other.url == url &&
          identical(other.cache, cache));

  @override
  int get hashCode => Object.hash(url, identityHashCode(cache));
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 7)],
    ),
    child: Icon(icon, color: color, size: 24),
  );
}

class _MapHint extends StatelessWidget {
  const _MapHint({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .94),
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 8)],
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: WakeColors.ink,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

class _MapAttribution extends StatelessWidget {
  const _MapAttribution();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .9),
      borderRadius: BorderRadius.circular(4),
    ),
    child: const Padding(
      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      child: Text(
        '© OpenStreetMap contributors',
        style: TextStyle(color: WakeColors.ink, fontSize: 9),
      ),
    ),
  );
}
