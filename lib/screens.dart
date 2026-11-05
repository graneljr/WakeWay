import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;

import 'ui.dart';
import 'wake_map.dart';
import 'wakeway_controller.dart';

enum _AlarmSoundChoice { wakeWayTone, classicTone, systemRingtone, deviceMusic }

Future<void> _showAlarmSoundPicker(
  BuildContext context,
  WakeWayController controller,
  ValueChanged<String> onSelected,
) async {
  final choice = await showModalBottomSheet<_AlarmSoundChoice>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.music_note_rounded),
            title: const Text('WakeWay alarm'),
            onTap: () => Navigator.pop(context, _AlarmSoundChoice.wakeWayTone),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text('Classic alarm'),
            onTap: () => Navigator.pop(context, _AlarmSoundChoice.classicTone),
          ),
          ListTile(
            leading: const Icon(Icons.ring_volume_rounded),
            title: const Text('Choose a device ringtone'),
            onTap: () =>
                Navigator.pop(context, _AlarmSoundChoice.systemRingtone),
          ),
          ListTile(
            leading: const Icon(Icons.library_music_rounded),
            title: const Text('Choose music from this device'),
            onTap: () => Navigator.pop(context, _AlarmSoundChoice.deviceMusic),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (choice == null) return;

  try {
    String? selectedName;
    switch (choice) {
      case _AlarmSoundChoice.wakeWayTone:
        selectedName = 'WakeWay alarm';
        await controller.setAlarmSound(selectedName);
      case _AlarmSoundChoice.classicTone:
        selectedName = 'Classic alarm';
        await controller.setAlarmSound(selectedName);
      case _AlarmSoundChoice.systemRingtone:
        selectedName = await controller.pickSystemRingtone();
      case _AlarmSoundChoice.deviceMusic:
        selectedName = await controller.pickDeviceMusic();
    }
    if (selectedName != null) onSelected(selectedName);
  } on Object catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not select alarm audio: $error')),
    );
  }
}

class HeroRoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = const Color(0xFF35536F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(-4, size.height * .9)
      ..cubicTo(
        size.width * .36,
        size.height * .17,
        size.width * .4,
        size.height * 1.12,
        size.width * .92,
        size.height * .25,
      );
    canvas.drawPath(path, road);
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF7693AB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round,
    );
    final dashes = Paint()
      ..color = const Color(0xFF7693AB)
      ..strokeWidth = 1.2;
    for (var i = 0; i < 5; i++) {
      canvas.drawCircle(
        Offset(
          size.width * (.17 + i * .16),
          size.height * (.65 - (i % 3) * .1),
        ),
        1.5,
        dashes,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DestinationScreen extends StatefulWidget {
  const DestinationScreen({
    super.key,
    required this.controller,
    required this.onContinue,
  });

  final WakeWayController controller;
  final ValueChanged<WakeDestination> onContinue;

  @override
  State<DestinationScreen> createState() => _DestinationScreenState();
}

class _DestinationScreenState extends State<DestinationScreen> {
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  late WakeDestination? _selected = widget.controller.defaultDestination;
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
    final point = _selectedPoint;
    if (point == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a place or tap the map first.')),
      );
      return;
    }
    final source = _selected;
    final place = WakeDestination(
      id: source?.id ?? '${point.latitude}_${point.longitude}',
      name: _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : source?.name ?? 'Pinned destination',
      address: source?.address ?? 'Selected on map',
      latitude: point.latitude,
      longitude: point.longitude,
    );
    if (_saveDestination) await widget.controller.saveDestination(place);
    if (mounted) widget.onContinue(place);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) => Scaffold(
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
                key: ValueKey(_selected?.id),
                controller: widget.controller,
                selectedPoint: _selectedPoint,
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
                  style: const TextStyle(color: WakeColors.muted, fontSize: 11),
                ),
              const SizedBox(height: 17),
              const SectionLabel('Saved destinations'),
              const SizedBox(height: 8),
              SurfaceCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 5,
                ),
                child: Column(
                  children: widget.controller.destinations
                      .map(
                        (place) => _SelectableDestination(
                          icon: place.name.toLowerCase().contains('home')
                              ? Icons.home_rounded
                              : Icons.place_rounded,
                          title: place.name,
                          subtitle:
                              '${place.address} · ${place.latitude.toStringAsFixed(4)}, ${place.longitude.toStringAsFixed(4)}',
                          selected: _selected?.id == place.id,
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
                label: 'Continue to alarm setup',
                icon: Icons.arrow_forward_rounded,
                onPressed: _continue,
              ),
            ],
          ),
        ),
      ),
    ),
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

enum AlarmMode { distance, advance }

Future<int?> _requestCustomRadius(BuildContext context, int current) async {
  final controller = TextEditingController(text: '$current');
  final radius = await showDialog<int>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Custom trigger radius'),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Distance',
          suffixText: 'meters',
          helperText: 'Enter a value from 50 to 5,000 m.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final value = int.tryParse(controller.text.trim());
            if (value != null && value >= 50 && value <= 5000) {
              Navigator.pop(dialogContext, value);
            }
          },
          child: const Text('Apply'),
        ),
      ],
    ),
  );
  controller.dispose();
  return radius;
}

Future<double?> _requestWarningDistance(
  BuildContext context,
  double current,
) async {
  var value = current.clamp(.5, 5).toDouble();
  return showDialog<double>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('First warning distance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${value.toStringAsFixed(1)} km'),
            Slider(
              value: value,
              min: .5,
              max: 5,
              divisions: 9,
              onChanged: (next) => setDialogState(() => value = next),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, value),
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

class AlarmConfigScreen extends StatefulWidget {
  const AlarmConfigScreen({
    super.key,
    required this.destination,
    required this.controller,
    required this.initialAlarmPoint,
    required this.onStartTrip,
  });
  final WakeDestination destination;
  final WakeWayController controller;
  final LatLng? initialAlarmPoint;
  final ValueChanged<WakeTripOptions> onStartTrip;

  @override
  State<AlarmConfigScreen> createState() => _AlarmConfigScreenState();
}

class _AlarmConfigScreenState extends State<AlarmConfigScreen> {
  AlarmMode _mode = AlarmMode.advance;
  late int _radius = widget.controller.radiusMeters;
  late double _warning = widget.controller.warningDistanceMeters / 1000;
  late bool _vibration = widget.controller.vibrationEnabled;
  late bool _repeat = widget.controller.repeatAlarm;
  late int _snoozeDuration = widget.controller.snoozeMinutes;
  late String _sound = widget.controller.alarmSound;
  late LatLng _alarmPoint =
      widget.initialAlarmPoint ??
      LatLng(widget.destination.latitude, widget.destination.longitude);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Alarm setup')),
    body: SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose when to wake',
              style: TextStyle(
                color: WakeColors.ink,
                fontSize: 23,
                fontWeight: FontWeight.w700,
                letterSpacing: -.45,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Destination · ${widget.destination.name}',
              style: const TextStyle(color: WakeColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            _AlarmModeCard(
              selected: _mode == AlarmMode.distance,
              icon: Icons.near_me_outlined,
              title: 'Distance from destination',
              subtitle: 'Wake me when I’m within a set distance of my stop.',
              onTap: () => setState(() => _mode = AlarmMode.distance),
            ),
            const SizedBox(height: 10),
            _AlarmModeCard(
              selected: _mode == AlarmMode.advance,
              icon: Icons.add_location_alt_outlined,
              title: 'Advance alarm point',
              subtitle: 'Wake me at the marker I placed on my route.',
              onTap: () => setState(() => _mode = AlarmMode.advance),
            ),
            const SizedBox(height: 17),
            SurfaceCard(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('Trigger radius'),
                  const SizedBox(height: 3),
                  const Text(
                    'The alarm starts when GPS enters this circle.',
                    style: TextStyle(color: WakeColors.muted, fontSize: 11),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children:
                        [100, 200, 300, 500, 1000]
                            .map(
                              (value) => ChoiceChip(
                                label: Text(
                                  value == 1000 ? '1 km' : '$value m',
                                ),
                                selected: _radius == value,
                                onSelected: (_) =>
                                    setState(() => _radius = value),
                                selectedColor: WakeColors.blueSoft,
                                labelStyle: TextStyle(
                                  color: _radius == value
                                      ? WakeColors.blue
                                      : WakeColors.muted,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                                side: BorderSide(
                                  color: _radius == value
                                      ? WakeColors.blue.withValues(alpha: .22)
                                      : WakeColors.line,
                                ),
                              ),
                            )
                            .toList()
                          ..add(
                            ChoiceChip(
                              label: Text(
                                [100, 200, 300, 500, 1000].contains(_radius)
                                    ? 'Custom'
                                    : 'Custom · $_radius m',
                              ),
                              selected: ![
                                100,
                                200,
                                300,
                                500,
                                1000,
                              ].contains(_radius),
                              onSelected: (_) async {
                                final value = await _requestCustomRadius(
                                  context,
                                  [100, 200, 300, 500, 1000].contains(_radius)
                                      ? 750
                                      : _radius,
                                );
                                if (value != null && mounted) {
                                  setState(() => _radius = value);
                                }
                              },
                              selectedColor: WakeColors.blueSoft,
                              labelStyle: TextStyle(
                                color:
                                    [100, 200, 300, 500, 1000].contains(_radius)
                                    ? WakeColors.muted
                                    : WakeColors.blue,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 15),
                  WakeMapView(
                    key: ValueKey(widget.destination.id),
                    controller: widget.controller,
                    destination: widget.destination,
                    selectedPoint: _alarmPoint,
                    alarmRadiusMeters: _radius,
                    height: 190,
                    onPointSelected: (point) =>
                        setState(() => _alarmPoint = point),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SurfaceCard(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.notifications_active_outlined,
                        color: WakeColors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'First warning',
                          style: TextStyle(
                            color: WakeColors.ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        '${_warning.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          color: WakeColors.blue,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _warning,
                    min: .5,
                    max: 5,
                    divisions: 9,
                    label: '${_warning.toStringAsFixed(1)} km',
                    onChanged: (value) => setState(() => _warning = value),
                  ),
                  const Divider(height: 1, color: WakeColors.line),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.music_note_rounded,
                      color: WakeColors.blue,
                    ),
                    title: const Text(
                      'Alarm sound',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      _sound,
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: WakeColors.muted,
                    ),
                    onTap: () => _showAlarmSoundPicker(
                      context,
                      widget.controller,
                      (value) => setState(() => _sound = value),
                    ),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Vibration',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    value: _vibration,
                    onChanged: (value) => setState(() => _vibration = value),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Repeat alarm',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'Restart the selected audio when it ends',
                      style: TextStyle(fontSize: 10),
                    ),
                    value: _repeat,
                    onChanged: (value) => setState(() => _repeat = value),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.snooze_rounded,
                      color: WakeColors.blue,
                    ),
                    title: const Text(
                      'Snooze duration',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      '$_snoozeDuration minutes',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: const Icon(
                      Icons.expand_more_rounded,
                      color: WakeColors.muted,
                    ),
                    onTap: () => setState(
                      () => _snoozeDuration = _snoozeDuration == 5
                          ? 10
                          : _snoozeDuration == 10
                          ? 15
                          : 5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: WakeColors.blueSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: WakeColors.blue,
                    size: 18,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Your alarm will sound when you enter the ${_radius == 1000 ? '1 km' : '$_radius m'} radius around your selected point. You can stop or snooze it at any time.',
                      style: const TextStyle(
                        color: WakeColors.ink,
                        fontSize: 11,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Start trip monitoring',
              icon: Icons.gps_fixed_rounded,
              onPressed: () => widget.onStartTrip(
                WakeTripOptions(
                  radiusMeters: _radius,
                  warningDistanceMeters: (_warning * 1000).round(),
                  vibration: _vibration,
                  repeatAlarm: _repeat,
                  snoozeMinutes: _snoozeDuration,
                  alarmSound: _sound,
                  alarmSoundPath: widget.controller.customAlarmSoundPath,
                  useAdvancePoint: _mode == AlarmMode.advance,
                  advanceLatitude: _alarmPoint.latitude,
                  advanceLongitude: _alarmPoint.longitude,
                ),
              ),
            ),
            const SizedBox(height: 7),
            const Center(
              child: Text(
                'Keep WakeWay open in the background for reliable alerts.',
                style: TextStyle(color: WakeColors.muted, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AlarmModeCard extends StatelessWidget {
  const _AlarmModeCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? WakeColors.blueSoft : Colors.white,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? WakeColors.blue.withValues(alpha: .45)
                : WakeColors.line,
          ),
        ),
        child: Row(
          children: [
            IconTile(
              icon: icon,
              color: selected ? WakeColors.blue : WakeColors.muted,
              background: selected ? Colors.white : WakeColors.canvas,
              size: 42,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: WakeColors.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: WakeColors.muted,
                      fontSize: 10,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? WakeColors.blue : WakeColors.muted,
              size: 20,
            ),
          ],
        ),
      ),
    ),
  );
}

class ActiveTripScreen extends StatelessWidget {
  const ActiveTripScreen({
    super.key,
    required this.controller,
    required this.onStop,
  });
  final WakeWayController controller;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => PopScope(
      canPop: !controller.isMonitoring,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Trip in progress'),
          automaticallyImplyLeading: false,
          actions: [
            StatusPill(
              label: controller.isMonitoring ? 'Tracking' : 'Stopped',
              icon: Icons.gps_fixed_rounded,
              color: controller.isMonitoring
                  ? WakeColors.green
                  : WakeColors.red,
            ),
            const SizedBox(width: 14),
          ],
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WakeMapView(
                  controller: controller,
                  destination: controller.activeDestination,
                  selectedPoint: LatLng(
                    controller.alarmLatitude,
                    controller.alarmLongitude,
                  ),
                  alarmRadiusMeters: controller.radiusMeters,
                  height: 320,
                ),
                const SizedBox(height: 15),
                SurfaceCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const IconTile(
                        icon: Icons.notifications_active_rounded,
                        color: WakeColors.blue,
                        background: WakeColors.blueSoft,
                        size: 50,
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Distance to alarm point',
                              style: TextStyle(
                                color: WakeColors.muted,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              controller.formatDistance(
                                controller.distanceToAlarmMeters,
                              ),
                              style: const TextStyle(
                                color: WakeColors.ink,
                                fontWeight: FontWeight.w800,
                                fontSize: 23,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Alarm radius · ${controller.formatDistance(controller.radiusMeters.toDouble())}',
                              style: const TextStyle(
                                color: WakeColors.muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 13),
                SurfaceCard(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      LabeledIconRow(
                        icon: Icons.location_on_rounded,
                        title:
                            controller.activeDestination?.name ?? 'Destination',
                        subtitle: controller.activeDestination?.address ?? '',
                        color: WakeColors.green,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, color: WakeColors.line),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _TripMetric(
                              icon: Icons.my_location_rounded,
                              title: 'GPS accuracy',
                              value: controller.currentPosition == null
                                  ? 'Waiting'
                                  : '± ${controller.currentPosition!.accuracy.round()} m',
                              color: WakeColors.blue,
                            ),
                          ),
                          Expanded(
                            child: _TripMetric(
                              icon: Icons.access_time_rounded,
                              title: 'Started',
                              value: controller.tripStartedAt == null
                                  ? '—'
                                  : TimeOfDay.fromDateTime(
                                      controller.tripStartedAt!,
                                    ).format(context),
                              color: WakeColors.green,
                            ),
                          ),
                          Expanded(
                            child: _TripMetric(
                              icon: Icons.notifications_active_outlined,
                              title: 'Alarm',
                              value: controller.isAlarmActive
                                  ? 'Ringing'
                                  : 'Armed',
                              color: WakeColors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (controller.lastError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    controller.lastError!,
                    style: const TextStyle(color: WakeColors.red),
                  ),
                ],
                const SizedBox(height: 13),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: WakeColors.greenSoft,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.shield_rounded,
                        color: WakeColors.green,
                        size: 19,
                      ),
                      SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'Location monitoring is active while this trip is running.',
                          style: TextStyle(
                            color: WakeColors.green,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: onStop,
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: const Text('Stop trip'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: WakeColors.red,
                    minimumSize: const Size.fromHeight(51),
                    side: const BorderSide(color: Color(0xFFF2C9CA)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _TripMetric extends StatelessWidget {
  const _TripMetric({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: WakeColors.muted, fontSize: 9),
            ),
          ),
        ],
      ),
      const SizedBox(height: 5),
      Text(
        value,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class AlarmTriggeredScreen extends StatefulWidget {
  const AlarmTriggeredScreen({
    super.key,
    required this.destination,
    required this.controller,
    required this.onStop,
    required this.onSnooze,
  });
  final String destination;
  final WakeWayController controller;
  final VoidCallback onStop;
  final VoidCallback onSnooze;

  @override
  State<AlarmTriggeredScreen> createState() => _AlarmTriggeredScreenState();
}

class _AlarmTriggeredScreenState extends State<AlarmTriggeredScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
      lowerBound: .91,
      upperBound: 1,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) => Scaffold(
      backgroundColor: const Color(0xFFFFF5F3),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 27),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.circle, color: WakeColors.red, size: 10),
                  const SizedBox(width: 7),
                  const Text(
                    'WAKEWAY ALARM',
                    style: TextStyle(
                      color: WakeColors.red,
                      letterSpacing: 1.4,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: widget.onStop,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: WakeColors.ink,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              ScaleTransition(
                scale: _pulse,
                child: Container(
                  width: 144,
                  height: 144,
                  decoration: const BoxDecoration(
                    color: WakeColors.redSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.notifications_active_rounded,
                      size: 69,
                      color: WakeColors.red,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 31),
              const Text(
                'You’re close to\nyour destination!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: WakeColors.ink,
                  fontSize: 31,
                  height: 1.12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.8,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Wake up and get ready to get off.',
                textAlign: TextAlign.center,
                style: TextStyle(color: WakeColors.muted, fontSize: 15),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: WakeColors.green,
                      size: 19,
                    ),
                    SizedBox(width: 7),
                    Text(
                      widget.destination,
                      style: const TextStyle(
                        color: WakeColors.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(width: 14),
                    Text(
                      widget.controller.formatDistance(
                        widget.controller.distanceToAlarmMeters,
                      ),
                      style: TextStyle(
                        color: WakeColors.red,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Stop alarm',
                icon: Icons.stop_circle_outlined,
                color: WakeColors.red,
                onPressed: widget.onStop,
                height: 60,
              ),
              const SizedBox(height: 11),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: widget.onSnooze,
                  icon: const Icon(Icons.snooze_rounded),
                  label: Text(
                    'Snooze · ${widget.controller.snoozeMinutes} min',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: WakeColors.ink,
                    side: const BorderSide(color: Color(0xFFE8D9D7)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Please mind your belongings as you get off.',
                style: TextStyle(color: WakeColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class OfflineMapsScreen extends StatelessWidget {
  const OfflineMapsScreen({super.key, required this.controller});

  final WakeWayController controller;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: const Text('Offline maps')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 26),
          children: [
            const PageHeading(
              'Offline trip essentials',
              subtitle:
                  'WakeWay keeps your places and trip records on this device.',
            ),
            const SizedBox(height: 17),
            SurfaceCard(
              color: WakeColors.navy,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.offline_pin_rounded,
                        color: Color(0xFF8AD9B8),
                        size: 21,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'LOCAL DATA',
                        style: TextStyle(
                          color: Color(0xFFB8CBDA),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Text(
                    '${controller.destinations.length} saved places · ${controller.trips.length} trip records',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'GPS distance monitoring, saved destinations, and trip history do not need mobile data once a destination is saved.',
                    style: TextStyle(
                      color: Color(0xFFB8CBDA),
                      fontSize: 11,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SurfaceCard(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
              child: SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Offline mode',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                subtitle: const Text(
                  'Show saved map tiles only. GPS tracking stays available.',
                  style: TextStyle(fontSize: 11),
                ),
                value: controller.offlineMode,
                onChanged: controller.setOfflineMode,
              ),
            ),
            const SizedBox(height: 14),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('Map tiles'),
                  const SizedBox(height: 6),
                  const Text(
                    'Tiles are saved automatically as you view the map online (up to 1 GB). Offline mode shows saved tiles only. Pan and zoom across an area while online to cache it before your trip; this does not download a whole region.',
                    style: TextStyle(
                      color: WakeColors.muted,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        controller.offlineMode
                            ? Icons.cloud_off_rounded
                            : Icons.cloud_done_rounded,
                        color: controller.offlineMode
                            ? WakeColors.muted
                            : WakeColors.green,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          controller.offlineMode
                              ? 'Online map requests paused'
                              : 'Map tiles load when connected',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class SavedDestinationsScreen extends StatefulWidget {
  const SavedDestinationsScreen({
    super.key,
    required this.controller,
    required this.onAdd,
    required this.onSelect,
  });

  final WakeWayController controller;
  final VoidCallback onAdd;
  final ValueChanged<WakeDestination> onSelect;

  @override
  State<SavedDestinationsScreen> createState() =>
      _SavedDestinationsScreenState();
}

class _SavedDestinationsScreenState extends State<SavedDestinationsScreen> {
  Future<void> _rename(WakeDestination place) async {
    final editor = TextEditingController(text: place.name);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename destination'),
        content: TextField(
          controller: editor,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, editor.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    editor.dispose();
    if (name != null) await widget.controller.renameDestination(place, name);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: const Text('Saved destinations')),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your familiar places',
                style: TextStyle(
                  color: WakeColors.ink,
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.45,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Pick a saved stop to set up your next ride.',
                style: TextStyle(color: WakeColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Add destination',
                icon: Icons.add_location_alt_rounded,
                onPressed: widget.onAdd,
              ),
              const SizedBox(height: 17),
              if (widget.controller.destinations.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No saved destinations yet.'),
                  ),
                ),
              ...widget.controller.destinations.map(
                (place) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SurfaceCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        IconTile(
                          icon: place.name.toLowerCase().contains('home')
                              ? Icons.home_rounded
                              : Icons.place_rounded,
                          color: WakeColors.blue,
                          background: WakeColors.blueSoft,
                          size: 45,
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: InkWell(
                            onTap: () => widget.onSelect(place),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  place.name,
                                  style: const TextStyle(
                                    color: WakeColors.ink,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  place.address,
                                  style: const TextStyle(
                                    color: WakeColors.muted,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${place.latitude.toStringAsFixed(5)}, ${place.longitude.toStringAsFixed(5)}',
                                  style: const TextStyle(
                                    color: WakeColors.muted,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert_rounded,
                            color: WakeColors.muted,
                          ),
                          onSelected: (action) {
                            if (action == 'delete') {
                              widget.controller.removeDestination(place);
                            } else if (action == 'edit') {
                              _rename(place);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Rename')),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Center(
                child: Text(
                  'Destinations stay on this device and work offline.',
                  style: TextStyle(color: WakeColors.muted, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.controller});

  final WakeWayController controller;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int _radius;
  late bool _vibration;
  late bool _offlineMode;
  late bool _batterySaverNotice;
  late String _sound;
  late String _units;
  late int _snoozeDuration;

  @override
  void initState() {
    super.initState();
    _radius = widget.controller.radiusMeters;
    _vibration = widget.controller.vibrationEnabled;
    _offlineMode = widget.controller.offlineMode;
    _batterySaverNotice = widget.controller.batteryTipsEnabled;
    _sound = widget.controller.alarmSound;
    _units = widget.controller.useMetricUnits
        ? 'Metric (m / km)'
        : 'Imperial (ft / mi)';
    _snoozeDuration = widget.controller.snoozeMinutes;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Settings')),
    body: SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 26),
        children: [
          const PageHeading(
            'Make it yours',
            subtitle: 'Set the defaults you want for every commute.',
          ),
          const SizedBox(height: 17),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DEFAULT ALARM',
                  style: TextStyle(
                    color: WakeColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Trigger radius',
                  style: TextStyle(
                    color: WakeColors.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 7,
                  children:
                      [100, 200, 300, 500, 1000]
                          .map(
                            (value) => ChoiceChip(
                              label: Text(value == 1000 ? '1 km' : '$value m'),
                              selected: _radius == value,
                              onSelected: (_) {
                                setState(() => _radius = value);
                                widget.controller.setRadius(value);
                              },
                              selectedColor: WakeColors.blueSoft,
                              labelStyle: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _radius == value
                                    ? WakeColors.blue
                                    : WakeColors.muted,
                              ),
                            ),
                          )
                          .toList()
                        ..add(
                          ChoiceChip(
                            label: Text(
                              [100, 200, 300, 500, 1000].contains(_radius)
                                  ? 'Custom'
                                  : 'Custom · $_radius m',
                            ),
                            selected: ![
                              100,
                              200,
                              300,
                              500,
                              1000,
                            ].contains(_radius),
                            onSelected: (_) async {
                              final value = await _requestCustomRadius(
                                context,
                                [100, 200, 300, 500, 1000].contains(_radius)
                                    ? 750
                                    : _radius,
                              );
                              if (value != null && mounted) {
                                setState(() => _radius = value);
                                widget.controller.setRadius(value);
                              }
                            },
                            selectedColor: WakeColors.blueSoft,
                            labelStyle: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color:
                                  [100, 200, 300, 500, 1000].contains(_radius)
                                  ? WakeColors.muted
                                  : WakeColors.blue,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: WakeColors.line),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.notifications_active_outlined,
                    color: WakeColors.red,
                  ),
                  title: const Text(
                    'First warning distance',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${(widget.controller.warningDistanceMeters / 1000).toStringAsFixed(1)} km before alarm point',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: WakeColors.muted,
                  ),
                  onTap: () async {
                    final value = await _requestWarningDistance(
                      context,
                      widget.controller.warningDistanceMeters / 1000,
                    );
                    if (value != null) {
                      await widget.controller.setWarningDistance(value);
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.music_note_rounded,
                    color: WakeColors.blue,
                  ),
                  title: const Text(
                    'Alarm sound',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(_sound, style: const TextStyle(fontSize: 11)),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: WakeColors.muted,
                  ),
                  onTap: () => _showAlarmSoundPicker(
                    context,
                    widget.controller,
                    (value) => setState(() => _sound = value),
                  ),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Vibration',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  value: _vibration,
                  onChanged: (value) {
                    setState(() => _vibration = value);
                    widget.controller.setVibration(value);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.snooze_rounded,
                    color: WakeColors.blue,
                  ),
                  title: const Text(
                    'Snooze duration',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '$_snoozeDuration minutes',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: WakeColors.muted,
                  ),
                  onTap: () {
                    setState(
                      () => _snoozeDuration = _snoozeDuration == 5
                          ? 10
                          : _snoozeDuration == 10
                          ? 15
                          : 5,
                    );
                    widget.controller.setSnoozeDuration(_snoozeDuration);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LOCATION & MAPS',
                  style: TextStyle(
                    color: WakeColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.straighten_rounded,
                    color: WakeColors.blue,
                  ),
                  title: const Text(
                    'Distance units',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(_units, style: const TextStyle(fontSize: 11)),
                  trailing: const Icon(
                    Icons.expand_more_rounded,
                    color: WakeColors.muted,
                  ),
                  onTap: () {
                    setState(
                      () => _units = _units.startsWith('Metric')
                          ? 'Imperial (ft / mi)'
                          : 'Metric (m / km)',
                    );
                    widget.controller.setMetricUnits(
                      _units.startsWith('Metric'),
                    );
                  },
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Offline mode',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'Use saved map tiles only; keep local trip data',
                    style: TextStyle(fontSize: 10),
                  ),
                  value: _offlineMode,
                  onChanged: (value) {
                    setState(() => _offlineMode = value);
                    widget.controller.setOfflineMode(value);
                  },
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Battery optimization reminder',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'Show tips for background tracking',
                    style: TextStyle(fontSize: 10),
                  ),
                  value: _batterySaverNotice,
                  onChanged: (value) {
                    setState(() => _batterySaverNotice = value);
                    widget.controller.setBatteryTipsEnabled(value);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.gps_fixed_rounded,
                    color: WakeColors.green,
                  ),
                  title: Text(
                    'GPS accuracy',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'Precise location recommended',
                    style: TextStyle(fontSize: 11),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: WakeColors.muted,
                  ),
                  onTap: () => widget.controller.refreshPermissionStatus(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'WakeWay checks your location while a trip is active. Background access helps keep your alarm reliable with the screen off.',
            style: TextStyle(
              color: WakeColors.muted,
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ),
    ),
  );
}

class GpsStatusScreen extends StatelessWidget {
  const GpsStatusScreen({super.key, required this.controller});

  final WakeWayController controller;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final locationReady = controller.locationReady;
      return Scaffold(
        appBar: AppBar(title: const Text('GPS & permissions')),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 26),
            children: [
              const PageHeading(
                'Ready for the road',
                subtitle: 'Check the device access WakeWay uses for a trip.',
              ),
              const SizedBox(height: 17),
              SurfaceCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 3,
                ),
                child: Column(
                  children: [
                    _PermissionRow(
                      icon: Icons.location_on_rounded,
                      title: 'Location permission',
                      detail: 'Needed to measure distance to your stop.',
                      status: controller.locationPermissionStatus,
                      ready: locationReady,
                    ),
                    const Divider(height: 1, color: WakeColors.line),
                    _PermissionRow(
                      icon: Icons.gps_fixed_rounded,
                      title: 'GPS availability',
                      detail: controller.currentPosition == null
                          ? 'Turn on location services and check your signal.'
                          : 'Current accuracy ± ${controller.currentPosition!.accuracy.round()} m.',
                      status: controller.locationServicesEnabled
                          ? 'Ready'
                          : 'Off',
                      ready: controller.locationServicesEnabled,
                    ),
                    const Divider(height: 1, color: WakeColors.line),
                    _PermissionRow(
                      icon: Icons.location_searching_rounded,
                      title: 'Trip tracking',
                      detail: 'Uses an Android foreground location notification while monitoring.',
                      status: controller.isMonitoring
                          ? 'Active'
                          : 'Ready at trip start',
                      ready: controller.isMonitoring || locationReady,
                    ),
                    const Divider(height: 1, color: WakeColors.line),
                    _PermissionRow(
                      icon: Icons.notifications_active_rounded,
                      title: 'Notifications',
                      detail: 'Shows proximity warnings and your alarm.',
                      status: controller.notificationsEnabled
                          ? 'Allowed'
                          : 'Not requested',
                      ready: controller.notificationsEnabled,
                    ),
                    const Divider(height: 1, color: WakeColors.line),
                    const _PermissionRow(
                      icon: Icons.volume_up_rounded,
                      title: 'Alarm audio',
                      detail: 'WakeWay plays a bundled sound when the alarm point is reached.',
                      status: 'Ready',
                      ready: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 13),
              if (controller.batteryTipsEnabled)
                const Text(
                  'WakeWay starts foreground location monitoring when you start a trip. Some Android devices may limit background work when battery saver is enabled.',
                  style: TextStyle(
                    color: WakeColors.muted,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Check location access',
                icon: Icons.my_location_rounded,
                onPressed: () async {
                  try {
                    await controller.locateOnce();
                  } on Object catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(error.toString())));
                    }
                  }
                },
              ),
              const SizedBox(height: 9),
              OutlinedButton.icon(
                onPressed: controller.requestNotificationPermission,
                icon: const Icon(Icons.notifications_active_outlined),
                label: const Text('Allow notifications'),
              ),
              const SizedBox(height: 9),
              OutlinedButton.icon(
                onPressed: Geolocator.openAppSettings,
                icon: const Icon(Icons.settings_rounded),
                label: const Text('Open app settings'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.icon,
    required this.title,
    required this.detail,
    required this.status,
    required this.ready,
  });
  final IconData icon;
  final String title;
  final String detail;
  final String status;
  final bool ready;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: WakeColors.blue, size: 20),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: WakeColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                detail,
                style: const TextStyle(
                  color: WakeColors.muted,
                  fontSize: 10,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          status,
          style: TextStyle(
            color: ready ? WakeColors.green : const Color(0xFFB27A25),
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
