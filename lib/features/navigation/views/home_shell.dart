import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:wakeway/core/database/data_sync_service.dart';
import 'package:wakeway/core/updates/app_update_service.dart';
import 'package:wakeway/features/auth/viewmodels/authentication.dart';
import 'package:wakeway/features/destinations/viewmodels/destination_view_model.dart';
import 'package:wakeway/features/destinations/views/saved_destinations_screen.dart';
import 'package:wakeway/features/home/views/home_screen.dart';
import 'package:wakeway/features/location/views/gps_status_screen.dart';
import 'package:wakeway/features/map/models/wake_destination.dart';
import 'package:wakeway/features/map/views/destination_screen.dart';
import 'package:wakeway/features/map/views/map_screen.dart';
import 'package:wakeway/features/map/views/offline_maps_screen.dart';
import 'package:wakeway/features/more/views/more_screen.dart';
import 'package:wakeway/features/settings/views/settings_screen.dart';
import 'package:wakeway/features/trips/models/trips.dart';
import 'package:wakeway/features/trips/views/active_trip_screen.dart';
import 'package:wakeway/features/trips/views/alarm_config_screen.dart';
import 'package:wakeway/features/trips/views/alarm_triggered_screen.dart';
import 'package:wakeway/features/trips/views/trips_screen.dart';
import 'package:wakeway/features/wake/viewmodels/wakeway_view_model.dart';
import 'package:wakeway/shared/ui.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.controller});

  final WakeWayViewModel controller;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late final DestinationViewModel _destinationViewModel;
  late final DataSyncService _dataSyncService;
  late final AppUpdateService _appUpdateService;
  int _selectedIndex = 0;
  int _seenAlarmEventCount = 0;
  bool _alarmRouteShowing = false;
  bool _isCheckingForUpdates = false;

  @override
  void initState() {
    super.initState();
    _destinationViewModel = DestinationViewModel(
      authenticationRepository: widget.controller.authenticationRepository,
    );
    _dataSyncService = DataSyncService(
      authenticationRepository: widget.controller.authenticationRepository,
    );
    _appUpdateService = AppUpdateService();
    unawaited(_initializeData());
    _seenAlarmEventCount = widget.controller.alarmEventCount;
    widget.controller.addListener(_onControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_checkForAppUpdates(showStatusWhenCurrent: false));
    });
  }

  Future<void> _checkForAppUpdates({
    required bool showStatusWhenCurrent,
  }) async {
    if (_isCheckingForUpdates) return;
    if (!Platform.isAndroid) {
      if (showStatusWhenCurrent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Install iOS updates through the App Store.'),
          ),
        );
      }
      return;
    }

    setState(() => _isCheckingForUpdates = true);
    try {
      if (!_appUpdateService.isConfigured) {
        if (showStatusWhenCurrent && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Configure WAKEWAY_GITHUB_REPOSITORY to check for updates.',
              ),
            ),
          );
        }
        return;
      }

      final release = await _appUpdateService.checkForUpdate();
      if (!mounted) return;
      if (release == null) {
        if (showStatusWhenCurrent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('WakeWay is up to date.')),
          );
        }
        return;
      }

      final shouldUpdate = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(
            Icons.system_update_alt_rounded,
            color: WakeColors.blue,
            size: 30,
          ),
          title: const Text('Update available'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WakeWay ${release.version} is available. You have ${release.installedVersion}.',
                  ),
                  if (release.releaseNotes.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'What’s new',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 5),
                    Text(release.releaseNotes.trim()),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Update'),
            ),
          ],
        ),
      );
      if (shouldUpdate != true || !mounted) return;

      final canInstall = await _appUpdateService.canInstallPackages();
      if (!canInstall) {
        final openSettings = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Allow WakeWay to install updates'),
            content: const Text(
              'Android needs permission to install APK updates from WakeWay. Open the app-specific setting, enable “Allow from this source,” then return and check for updates again.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Later'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Open settings'),
              ),
            ],
          ),
        );
        if (openSettings == true) {
          await _appUpdateService.openInstallPermissionSettings();
        }
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloading WakeWay ${release.version}…')),
      );
      final apkFile = await _appUpdateService.downloadApk(release);
      if (!mounted) return;
      await _appUpdateService.openApkInstaller(apkFile);
    } on Object catch (error) {
      if (!mounted || !showStatusWhenCurrent) return;
      final message = error
          .toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('Bad state: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not check for updates: $message')),
      );
    } finally {
      if (mounted) setState(() => _isCheckingForUpdates = false);
    }
  }

  Future<void> _initializeData() async {
    await Future.wait<void>([
      _destinationViewModel.initialize(),
      widget.controller.initialize(),
    ]);
    if (!mounted) return;

    try {
      await _dataSyncService.syncNow();
      if (!mounted) return;
      await Future.wait<void>([
        _destinationViewModel.refreshFromLocal(),
        widget.controller.refreshLocalTripData(),
      ]);
    } on Object {
      // Keep the cached SQLite data available while offline; More can retry.
    }
  }

  Future<void> _syncData() async {
    try {
      final summary = await _dataSyncService.syncNow();
      if (!mounted) return;
      await Future.wait<void>([
        _destinationViewModel.refreshFromLocal(),
        widget.controller.refreshLocalTripData(),
      ]);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Synced ${summary.destinationCount} saved places and '
            '${summary.tripCount} trips.',
          ),
        ),
      );
    } on Object catch (error) {
      if (!mounted) return;
      final message = error
          .toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('Bad state: ', '');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Sync failed: $message')));
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    widget.controller.dispose();
    _destinationViewModel.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (widget.controller.alarmEventCount <= _seenAlarmEventCount) return;
    _seenAlarmEventCount = widget.controller.alarmEventCount;
    if (_alarmRouteShowing) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.controller.isMonitoring && !_alarmRouteShowing) {
        _openAlarm();
      }
    });
  }

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  void _openAlarmSetup({WakeDestination? destination, LatLng? alarmPoint}) {
    final target = destination ?? _destinationViewModel.defaultDestination;
    if (target == null) {
      _openDestination();
      return;
    }
    final savedDestinationId =
        _destinationViewModel.destinations.any(
          (savedDestination) => savedDestination.id == target.id,
        )
        ? target.id
        : null;
    _push(
      AlarmConfigScreen(
        destination: target,
        controller: widget.controller,
        initialAlarmPoint: alarmPoint,
        onStartTrip: (options) async {
          try {
            if (!widget.controller.locationReady ||
                !widget.controller.notificationsEnabled) {
              final continueToPermissions = await _showTripPermissionPrompt();
              if (!continueToPermissions || !mounted) return;
            }
            await widget.controller.startTrip(
              destination: target,
              savedDestinationId: savedDestinationId,
              options: options,
              alarmLat: options.useAdvancePoint
                  ? options.advanceLatitude
                  : null,
              alarmLon: options.useAdvancePoint
                  ? options.advanceLongitude
                  : null,
            );
            if (!mounted) return;
            Navigator.of(context).pop();
            _push(
              ActiveTripScreen(
                controller: widget.controller,
                onStop: _confirmStopTrip,
              ),
            );
          } on Object catch (error) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error.toString().replaceFirst('Bad state: ', '')),
              ),
            );
          }
        },
      ),
    );
  }

  Future<bool> _showTripPermissionPrompt() async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          scrollable: true,
          icon: const Icon(
            Icons.shield_moon_outlined,
            color: WakeColors.blue,
            size: 32,
          ),
          title: const Text('Permissions for your trip'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TripPermissionItem(
                icon: Icons.location_on_outlined,
                title: 'Location access',
                description: 'Choose Precise in Android’s prompt for reliable stop detection. Location is used only during a trip you start, including while the screen is off.',
              ),
              SizedBox(height: 14),
              _TripPermissionItem(
                icon: Icons.notifications_active_outlined,
                title: 'Notifications',
                description: 'Shows trip monitoring status and lets WakeWay alert you near your stop.',
              ),
              SizedBox(height: 14),
              Text(
                'Android will ask for each permission next. You can change them later in Settings. WakeWay does not need access to your contacts, calls, microphone, or all device files.',
                style: TextStyle(
                  color: WakeColors.muted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      ) ??
      false;

  void _openActiveTrip() => _openAlarmSetup();

  void _resumeTripFromList(WakeTrip trip) {
    unawaited(_resumeTrip(trip));
  }

  Future<void> _resumeTrip(WakeTrip trip) async {
    if (widget.controller.isMonitoring) {
      if (widget.controller.activeTripId == trip.id) {
        _openMonitoringScreen();
      }
      return;
    }

    try {
      if (!widget.controller.locationReady ||
          !widget.controller.notificationsEnabled) {
        final continueToPermissions = await _showTripPermissionPrompt();
        if (!continueToPermissions || !mounted) return;
      }

      await widget.controller.resumeTrip(trip.id);
      if (!mounted) return;
      _openMonitoringScreen();
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
        ),
      );
    }
  }

  void _openMonitoringScreen() {
    _push(
      ActiveTripScreen(controller: widget.controller, onStop: _confirmStopTrip),
    );
  }

  void _openAlarm() {
    if (_alarmRouteShowing) return;
    _alarmRouteShowing = true;
    _push(
      AlarmTriggeredScreen(
        destination: widget.controller.activeDestination?.name ?? 'Your stop',
        controller: widget.controller,
        onStop: () async {
          await widget.controller.stopAlarm();
          if (mounted) _showTripEnded();
        },
        onSnooze: () async {
          await widget.controller.snoozeAlarm();
          if (mounted) {
            _alarmRouteShowing = false;
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  Future<void> _confirmStopTrip() async {
    final shouldStop = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('End this trip?'),
        content: const Text(
          'Location monitoring will stop and the alarm will be disarmed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep monitoring'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('End trip'),
          ),
        ],
      ),
    );
    if (shouldStop == true) {
      await widget.controller.stopTrip();
      if (mounted) _showTripEnded();
    }
  }

  void _showTripEnded() {
    _alarmRouteShowing = false;
    Navigator.of(context).popUntil((route) => route.isFirst);
    setState(() => _selectedIndex = 0);
  }

  void _openDestination() {
    _push(
      DestinationScreen(
        controller: widget.controller,
        destinationViewModel: _destinationViewModel,
        onContinue: (destination) => _openAlarmSetup(destination: destination),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      AnimatedBuilder(
        animation: Listenable.merge([widget.controller, _destinationViewModel]),
        builder: (context, _) => HomeScreen(
          controller: widget.controller,
          destinationViewModel: _destinationViewModel,
          onStartTrip: _openActiveTrip,
          onSetDestination: _openDestination,
          onSaved: () => _push(
            SavedDestinationsScreen(
              viewModel: _destinationViewModel,
              onAdd: _openDestination,
              onSelect: (place) => _openAlarmSetup(destination: place),
            ),
          ),
          onOfflineMaps: () => _push(
            OfflineMapsScreen(
              controller: widget.controller,
              destinationViewModel: _destinationViewModel,
            ),
          ),
          onHistory: () => _setTab(2),
          onGpsStatus: () =>
              _push(GpsStatusScreen(controller: widget.controller)),
        ),
      ),
      AnimatedBuilder(
        animation: Listenable.merge([widget.controller, _destinationViewModel]),
        builder: (context, _) => MapScreen(
          controller: widget.controller,
          destinationViewModel: _destinationViewModel,
          onConfirm: (selection) => _openAlarmSetup(
            destination: selection.$1,
            alarmPoint: selection.$2,
          ),
        ),
      ),
      TripsScreen(
        controller: widget.controller,
        onResumeTrip: _resumeTripFromList,
      ),
      MoreScreen(
        onSaved: () => _push(
          SavedDestinationsScreen(
            viewModel: _destinationViewModel,
            onAdd: _openDestination,
            onSelect: (place) => _openAlarmSetup(destination: place),
          ),
        ),
        onOfflineMaps: () => _push(
          OfflineMapsScreen(
            controller: widget.controller,
            destinationViewModel: _destinationViewModel,
          ),
        ),
        onSettings: () => _push(SettingsScreen(controller: widget.controller)),
        onGpsStatus: () =>
            _push(GpsStatusScreen(controller: widget.controller)),
        onHistory: () => _setTab(2),
        onSync: _syncData,
        onCheckForUpdates: () =>
            unawaited(_checkForAppUpdates(showStatusWhenCurrent: true)),
        isCheckingForUpdates: _isCheckingForUpdates,
      ),
    ];

    return AnimatedBuilder(
      animation: Listenable.merge([widget.controller, _destinationViewModel]),
      builder: (context, _) => Scaffold(
        body: IndexedStack(index: _selectedIndex, children: screens),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _setTab,
          backgroundColor: Colors.white,
          indicatorColor: WakeColors.blue.withValues(alpha: 0.1),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map_rounded),
              label: 'Map',
            ),
            NavigationDestination(
              icon: Icon(Icons.route_outlined),
              selectedIcon: Icon(Icons.route_rounded),
              label: 'Trips',
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view_rounded),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }

  void _setTab(int index) => setState(() => _selectedIndex = index);
}

class _TripPermissionItem extends StatelessWidget {
  const _TripPermissionItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: WakeColors.blue, size: 21),
      const SizedBox(width: 11),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: WakeColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              description,
              style: const TextStyle(
                color: WakeColors.muted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
