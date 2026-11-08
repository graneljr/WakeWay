import 'package:flutter/material.dart';
import 'package:wakeway/features/settings/views/alarm_setting_dialogs.dart';
import 'package:wakeway/features/settings/views/alarm_sound_picker.dart';
import 'package:wakeway/features/wake/viewmodels/wakeway_view_model.dart';
import 'package:wakeway/shared/ui.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.controller});

  final WakeWayViewModel controller;

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
                              final value = await requestCustomRadius(
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
                    final value = await requestWarningDistance(
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
