import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:wakeway/features/map/models/wake_destination.dart';
import 'package:wakeway/features/map/widgets/wake_map_view.dart';
import 'package:wakeway/features/settings/views/alarm_setting_dialogs.dart';
import 'package:wakeway/features/settings/views/alarm_sound_picker.dart';
import 'package:wakeway/features/trips/models/wake_trip_options.dart';
import 'package:wakeway/features/wake/viewmodels/wakeway_view_model.dart';
import 'package:wakeway/shared/ui.dart';

enum AlarmMode { distance, advance }

class AlarmConfigScreen extends StatefulWidget {
  const AlarmConfigScreen({
    super.key,
    required this.destination,
    required this.controller,
    required this.initialAlarmPoint,
    required this.onStartTrip,
  });
  final WakeDestination destination;
  final WakeWayViewModel controller;
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
                                final value = await requestCustomRadius(
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
                    onTap: () => showAlarmSoundPicker(
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
