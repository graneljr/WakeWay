import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:wakeway/core/database/app_database.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens.dart';
import 'ui.dart';
import 'wakeway_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = WakeWayController();
  await controller.initialize();
  await SupabaseService.initialize();
  await dotenv.load(fileName: '.env');
  runApp(WakeWayApp(controller: controller));
}

class WakeWayApp extends StatelessWidget {
  const WakeWayApp({super.key, required this.controller});
  final WakeWayController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WakeWay',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: WakeColors.canvas,
        colorScheme: ColorScheme.fromSeed(
          seedColor: WakeColors.blue,
          primary: WakeColors.blue,
          secondary: WakeColors.green,
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: WakeColors.canvas,
          foregroundColor: WakeColors.ink,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: WakeColors.ink,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: WakeColors.ink,
            fontSize: 30,
            height: 1.12,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.7,
          ),
          headlineSmall: TextStyle(
            color: WakeColors.ink,
            fontSize: 24,
            height: 1.18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
          titleLarge: TextStyle(
            color: WakeColors.ink,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: TextStyle(
            color: WakeColors.ink,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: TextStyle(color: WakeColors.ink, fontSize: 15),
          bodyMedium: TextStyle(color: WakeColors.muted, fontSize: 13),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      home: SplashScreen(controller: controller),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.controller});

  final WakeWayController controller;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
    _timer = Timer(const Duration(milliseconds: 1850), _openHome);
  }

  void _openHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => HomeShell(controller: widget.controller),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: SplashRoadPainter())),
          Center(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BrandMark(size: 94),
                    const SizedBox(height: 22),
                    Text(
                      'WakeWay',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sleep through the ride.\nWake at the right time.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: WakeColors.muted, height: 1.45),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: Center(
              child: TextButton(
                onPressed: _openHome,
                child: const Text('Get started'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.controller});

  final WakeWayController controller;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;
  int _seenAlarmEventCount = 0;
  bool _alarmRouteShowing = false;

  @override
  void initState() {
    super.initState();
    _seenAlarmEventCount = widget.controller.alarmEventCount;
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    widget.controller.dispose();
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
    final target = destination ?? widget.controller.defaultDestination;
    if (target == null) {
      _openDestination();
      return;
    }
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
        onContinue: (destination) => _openAlarmSetup(destination: destination),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) => HomeScreen(
          controller: widget.controller,
          onStartTrip: _openActiveTrip,
          onSetDestination: _openDestination,
          onSaved: () => _push(
            SavedDestinationsScreen(
              controller: widget.controller,
              onAdd: _openDestination,
              onSelect: (place) => _openAlarmSetup(destination: place),
            ),
          ),
          onOfflineMaps: () =>
              _push(OfflineMapsScreen(controller: widget.controller)),
          onHistory: () => _setTab(2),
          onGpsStatus: () =>
              _push(GpsStatusScreen(controller: widget.controller)),
        ),
      ),
      AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) => MapScreen(
          controller: widget.controller,
          onConfirm: (selection) => _openAlarmSetup(
            destination: selection.$1,
            alarmPoint: selection.$2,
          ),
        ),
      ),
      TripsScreen(controller: widget.controller),
      MoreScreen(
        onSaved: () => _push(
          SavedDestinationsScreen(
            controller: widget.controller,
            onAdd: _openDestination,
            onSelect: (place) => _openAlarmSetup(destination: place),
          ),
        ),
        onOfflineMaps: () =>
            _push(OfflineMapsScreen(controller: widget.controller)),
        onSettings: () => _push(SettingsScreen(controller: widget.controller)),
        onGpsStatus: () =>
            _push(GpsStatusScreen(controller: widget.controller)),
        onHistory: () => _setTab(2),
      ),
    ];

    return Scaffold(
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) =>
            IndexedStack(index: _selectedIndex, children: screens),
      ),
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
