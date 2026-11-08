import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:wakeway/features/destinations/viewmodels/destination_view_model.dart';
import 'package:wakeway/shared/ui.dart';
import 'package:wakeway/features/map/widgets/wake_map_view.dart';
import 'package:wakeway/features/map/models/wake_destination.dart';
import 'package:wakeway/features/wake/viewmodels/wakeway_view_model.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    required this.controller,
    required this.destinationViewModel,
    required this.onConfirm,
  });

  final WakeWayViewModel controller;
  final DestinationViewModel destinationViewModel;
  final ValueChanged<(WakeDestination, LatLng)> onConfirm;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late WakeDestination? _destination =
      widget.destinationViewModel.defaultDestination;
  LatLng? _alarmPoint;
  final TextEditingController _searchController = TextEditingController();
  List<WakeDestination> _results = const [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    final place = _destination;
    if (place != null) _alarmPoint = LatLng(place.latitude, place.longitude);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_destination == null) {
      final defaultDestination = widget.destinationViewModel.defaultDestination;
      if (defaultDestination != null) {
        _destination = defaultDestination;
        _alarmPoint = LatLng(
          defaultDestination.latitude,
          defaultDestination.longitude,
        );
      }
    }
  }

  Future<void> _search() async {
    setState(() => _searching = true);
    try {
      final results = await widget.controller.searchPlaces(
        _searchController.text,
      );
      if (mounted) setState(() => _results = results);
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Place search failed: $error')));
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeading(
            'Plan your stop',
            subtitle: 'Choose your stop, then tap the map to place the alarm.',
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x09000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Search a place or address',
                prefixIcon: Icon(Icons.search_rounded, color: WakeColors.blue),
                suffixIcon: IconButton(
                  onPressed: _searching ? null : _search,
                  icon: _searching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search_rounded),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          if (_results.isNotEmpty) ...[
            const SizedBox(height: 8),
            SurfaceCard(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Column(
                children: _results
                    .map(
                      (place) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.place_outlined,
                          color: WakeColors.blue,
                        ),
                        title: Text(
                          place.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          place.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => setState(() {
                          _destination = place;
                          _alarmPoint = LatLng(place.latitude, place.longitude);
                          _results = const [];
                        }),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
          const SizedBox(height: 13),
          DropdownButtonFormField<String>(
            initialValue: _destination?.id,
            decoration: const InputDecoration(
              labelText: 'Destination',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(),
            ),
            items: [
              if (_destination != null &&
                  !widget.destinationViewModel.destinations.any(
                    (place) => place.id == _destination!.id,
                  ))
                DropdownMenuItem(
                  value: _destination!.id,
                  child: Text(_destination!.name),
                ),
              ...widget.destinationViewModel.destinations.map(
                (place) =>
                    DropdownMenuItem(value: place.id, child: Text(place.name)),
              ),
            ],
            onChanged: (id) {
              final places = widget.destinationViewModel.destinations;
              WakeDestination? place;
              for (final candidate in places) {
                if (candidate.id == id) place = candidate;
              }
              place ??= _destination?.id == id ? _destination : null;
              final selectedPlace = place;
              if (selectedPlace == null) return;
              setState(() {
                _destination = selectedPlace;
                _alarmPoint = LatLng(
                  selectedPlace.latitude,
                  selectedPlace.longitude,
                );
              });
            },
          ),
          const SizedBox(height: 13),
          WakeMapView(
            key: ValueKey(_destination?.id),
            controller: widget.controller,
            destination: _destination,
            selectedPoint: _alarmPoint,
            alarmRadiusMeters: widget.controller.radiusMeters,
            height: 410,
            onPointSelected: (point) => setState(() {
              _alarmPoint = point;
              _destination ??= WakeDestination(
                id: '${point.latitude.toStringAsFixed(5)}_${point.longitude.toStringAsFixed(5)}',
                name: 'Pinned stop',
                address: 'Selected on map',
                latitude: point.latitude,
                longitude: point.longitude,
              );
            }),
          ),
          const SizedBox(height: 15),
          SurfaceCard(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                Row(
                  children: [
                    const IconTile(
                      icon: Icons.notifications_active_rounded,
                      color: WakeColors.red,
                      background: WakeColors.redSoft,
                      size: 42,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Alarm point',
                            style: TextStyle(
                              color: WakeColors.ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _alarmPoint == null
                                ? 'Tap the map to place it'
                                : '${_alarmPoint!.latitude.toStringAsFixed(5)}, ${_alarmPoint!.longitude.toStringAsFixed(5)}',
                            style: TextStyle(
                              color: WakeColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.tune_rounded,
                      color: WakeColors.muted,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                const Divider(height: 1, color: WakeColors.line),
                const SizedBox(height: 12),
                Row(
                  children: const [
                    Icon(
                      Icons.my_location_rounded,
                      size: 16,
                      color: WakeColors.blue,
                    ),
                    SizedBox(width: 7),
                    Text(
                      'Current location',
                      style: TextStyle(color: WakeColors.muted, fontSize: 11),
                    ),
                    Spacer(),
                    Icon(Icons.circle, size: 8, color: WakeColors.blue),
                    SizedBox(width: 4),
                    Text(
                      'Alarm point',
                      style: TextStyle(color: WakeColors.muted, fontSize: 11),
                    ),
                    SizedBox(width: 12),
                    Icon(
                      Icons.location_on_rounded,
                      size: 15,
                      color: WakeColors.green,
                    ),
                    SizedBox(width: 3),
                    Text(
                      'Stop',
                      style: TextStyle(color: WakeColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          PrimaryButton(
            label: 'Use this alarm point',
            icon: Icons.check_rounded,
            onPressed: _alarmPoint == null || _destination == null
                ? null
                : () => widget.onConfirm((_destination!, _alarmPoint!)),
          ),
        ],
      ),
    ),
  );
}
