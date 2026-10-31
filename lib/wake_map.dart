import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'ui.dart';
import 'wakeway_controller.dart';

const _defaultCenter = LatLng(14.5547, 121.0244);

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
  bool _mapReady = false;

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
              if (widget.controller?.offlineMode != true)
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.wakeway',
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
          if (widget.controller?.offlineMode != true)
            const Positioned(left: 10, bottom: 10, child: _MapAttribution()),
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
              bottom: 10,
              child: _MapHint(label: 'Offline mode · map tiles paused'),
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
