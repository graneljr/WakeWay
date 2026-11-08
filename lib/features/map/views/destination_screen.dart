import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:wakeway/features/destinations/viewmodels/destination_view_model.dart';
import 'package:wakeway/features/map/models/wake_destination.dart';
import 'package:wakeway/features/map/widgets/wake_map_view.dart';
import 'package:wakeway/features/wake/viewmodels/wakeway_view_model.dart';
import 'package:wakeway/shared/ui.dart';
import 'package:uuid/uuid.dart';
class DestinationScreen extends StatefulWidget {
  const DestinationScreen({
    super.key,
    required this.controller,
    required this.destinationViewModel,
    required this.onContinue,
  });

  final WakeWayViewModel controller;
  final DestinationViewModel destinationViewModel;
  final ValueChanged<WakeDestination> onContinue;

  @override
  State<DestinationScreen> createState() => _DestinationScreenState();
}

class _DestinationScreenState extends State<DestinationScreen> {
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  late WakeDestination? _selected =
      widget.destinationViewModel.defaultDestination;
  LatLng? _selectedPoint;
  List<WakeDestination> _results = const [];
  bool _saveDestination = true;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    final place = _selected;
    if (place != null) _selectedPoint = LatLng(place.latitude, place.longitude);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _searchPlaces() async {
    setState(() => _searching = true);
    try {
      final results = await widget.controller.searchPlaces(
        _searchController.text,
      );
      if (mounted) setState(() => _results = results);
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Search failed: $error')));
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _continue() async {
    final source = _selected ?? widget.destinationViewModel.defaultDestination;
    final point =
        _selectedPoint ??
        (source == null ? null : LatLng(source.latitude, source.longitude));
    if (point == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a place or tap the map first.')),
      );
      return;
    }
    final place = WakeDestination(
      id: Uuid().v4(),
      name: _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : source?.name ?? 'Pinned destination',
      address: source?.address ?? 'Selected on map',
      latitude: point.latitude,
      longitude: point.longitude,
    );
    if (_saveDestination) {
      final saved = await widget.destinationViewModel.saveDestination(place);
      if (!saved) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.destinationViewModel.errorMessage ??
                    'Could not save this destination.',
              ),
            ),
          );
        }
        return;
      }
    }
    if (mounted) widget.onContinue(place);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([
      widget.controller,
      widget.destinationViewModel,
    ]),
    builder: (context, _) {
      final selected =
          _selected ?? widget.destinationViewModel.defaultDestination;
      final isBusy =
          widget.destinationViewModel.isLoading ||
          widget.destinationViewModel.isSaving;
      return Scaffold(
        appBar: AppBar(title: const Text('Choose destination')),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Where are you getting off?',
                  style: TextStyle(
                    color: WakeColors.ink,
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.45,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Search while online, or choose a saved place.',
                  style: TextStyle(color: WakeColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _searchPlaces(),
                  decoration: InputDecoration(
                    hintText: 'Search address or place',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: WakeColors.blue,
                    ),
                    suffixIcon: IconButton(
                      icon: _searching
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search_rounded),
                      onPressed: _searching ? null : _searchPlaces,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 11),
                if (_results.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SurfaceCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
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
                                _selected = place;
                                _selectedPoint = LatLng(
                                  place.latitude,
                                  place.longitude,
                                );
                                _nameController.clear();
                                _results = const [];
                              }),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Pick on the map',
                        style: TextStyle(
                          color: WakeColors.ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          final position = await widget.controller.locateOnce();
                          final place = WakeDestination(
                            id: 'current-location',
                            name: 'Current location',
                            address: 'Your current position',
                            latitude: position.latitude,
                            longitude: position.longitude,
                          );
                          if (mounted) {
                            setState(() {
                              _selected = place;
                              _selectedPoint = LatLng(
                                position.latitude,
                                position.longitude,
                              );
                            });
                          }
                        } on Object catch (error) {
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(content: Text(error.toString())),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.my_location_rounded, size: 16),
                      label: const Text('My location'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                WakeMapView(
                  key: ValueKey(selected?.id),
                  controller: widget.controller,
                  selectedPoint:
                      _selectedPoint ??
                      (selected == null
                          ? null
                          : LatLng(selected.latitude, selected.longitude)),
                  height: 245,
                  onPointSelected: (point) {
                    setState(() {
                      _selectedPoint = point;
                      _selected = WakeDestination(
                        id: '${point.latitude.toStringAsFixed(5)}_${point.longitude.toStringAsFixed(5)}',
                        name: 'Pinned destination',
                        address: 'Selected on map',
                        latitude: point.latitude,
                        longitude: point.longitude,
                      );
                      _nameController.clear();
                    });
                  },
                ),
                const SizedBox(height: 8),
                if (_selectedPoint != null)
                  Text(
                    '${_selectedPoint!.latitude.toStringAsFixed(5)}, ${_selectedPoint!.longitude.toStringAsFixed(5)}',
                    style: const TextStyle(
                      color: WakeColors.muted,
                      fontSize: 11,
                    ),
                  ),
                const SizedBox(height: 17),
                const SectionLabel('Saved destinations'),
                if (widget.destinationViewModel.errorMessage != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    widget.destinationViewModel.errorMessage!,
                    style: const TextStyle(
                      color: WakeColors.red,
                      fontSize: 12,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: widget.destinationViewModel.isLoading
                        ? null
                        : widget.destinationViewModel.initialize,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry loading destinations'),
                  ),
                ],
                const SizedBox(height: 8),
                SurfaceCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 5,
                  ),
                  child: Column(
                    children: widget.destinationViewModel.destinations
                        .map(
                          (place) => _SelectableDestination(
                            icon: place.name.toLowerCase().contains('home')
                                ? Icons.home_rounded
                                : Icons.place_rounded,
                            title: place.name,
                            subtitle:
                                '${place.address} · ${place.latitude.toStringAsFixed(4)}, ${place.longitude.toStringAsFixed(4)}',
                            selected: selected?.id == place.id,
                            onTap: () => setState(() {
                              _selected = place;
                              _selectedPoint = LatLng(
                                place.latitude,
                                place.longitude,
                              );
                              _nameController.clear();
                            }),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name this destination (optional)',
                    prefixIcon: Icon(Icons.edit_location_alt_outlined),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.bookmark_add_outlined,
                      color: WakeColors.blue,
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Save as a new destination',
                        style: TextStyle(
                          color: WakeColors.ink,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Switch(
                      value: _saveDestination,
                      onChanged: (value) =>
                          setState(() => _saveDestination = value),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                PrimaryButton(
                  label: widget.destinationViewModel.isLoading
                      ? 'Loading destinations...'
                      : widget.destinationViewModel.isSaving
                      ? 'Saving destination...'
                      : 'Continue to alarm setup',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: isBusy ? null : _continue,
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _SelectableDestination extends StatelessWidget {
  const _SelectableDestination({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 1),
    leading: IconTile(
      icon: icon,
      color: WakeColors.blue,
      background: WakeColors.blueSoft,
      size: 40,
    ),
    title: Text(
      title,
      style: const TextStyle(
        color: WakeColors.ink,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
    ),
    subtitle: Text(
      subtitle,
      style: const TextStyle(color: WakeColors.muted, fontSize: 10),
    ),
    trailing: Icon(
      selected
          ? Icons.radio_button_checked_rounded
          : Icons.radio_button_off_rounded,
      color: selected ? WakeColors.blue : WakeColors.muted,
    ),
    onTap: onTap,
  );
}
