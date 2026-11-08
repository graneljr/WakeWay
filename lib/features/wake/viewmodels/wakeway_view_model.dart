import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakeway/features/map/models/wake_destination.dart';
import 'package:wakeway/features/trips/models/wake_trip_options.dart';
import 'package:wakeway/features/trips/models/wake_trip_record.dart';

class WakeWayViewModel extends ChangeNotifier {
  /// Creates the WakeWay application ViewModel.
  WakeWayViewModel();

  static const _tripsKey = 'wakeway.trips.v1';
  static const _settingsKey = 'wakeway.settings.v1';
  static const _searchCacheKey = 'wakeway.placeSearchCache.v1';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _alarmPlayer = AudioPlayer();
  static const MethodChannel _audioPickerChannel = MethodChannel(
    'com.example.wakeway/audio_picker',
  );
  final List<WakeTripRecord> _trips = [];
  final Map<String, List<WakeDestination>> _placeSearchCache = {};
  StreamSubscription<Position>? _positionSubscription;
  Timer? _snoozeTimer;
  SharedPreferences? _preferences;
  DateTime? _nextPlaceSearchAt;

  WakeDestination? activeDestination;
  Position? currentPosition;
  double? distanceToAlarmMeters;
  DateTime? tripStartedAt;
  String locationPermissionStatus = 'Not checked';
  bool locationServicesEnabled = false;
  bool notificationsEnabled = false;
  bool isMonitoring = false;
  bool alarmIsRinging = false;
  bool alarmIsSnoozed = false;
  bool warningWasShown = false;
  bool _alarmTriggeredInTrip = false;
  int alarmEventCount = 0;
  String? lastError;
  double alarmLatitude = 0;
  double alarmLongitude = 0;
  int radiusMeters = 300;
  int warningDistanceMeters = 1500;
  bool vibrationEnabled = true;
  bool repeatAlarm = true;
  int snoozeMinutes = 5;
  String alarmSound = 'WakeWay alarm';
  String? customAlarmSoundPath;
  bool offlineMode = false;
  bool useMetricUnits = true;
  bool batteryTipsEnabled = true;

  /// Returns the trip history.
  List<WakeTripRecord> get trips => List.unmodifiable(_trips);

  /// Indicates whether the alarm is ringing or snoozed.
  bool get isAlarmActive => alarmIsRinging || alarmIsSnoozed;

  /// Indicates whether location services and permission are ready.
  bool get locationReady =>
      locationServicesEnabled &&
      (locationPermissionStatus == 'whileInUse' ||
          locationPermissionStatus == 'always');

  /// Loads saved data and checks notification and location status.
  Future<void> initialize() async {
    _preferences = await SharedPreferences.getInstance();
    final tripJson = _preferences!.getString(_tripsKey);
    if (tripJson != null) {
      _trips.addAll(
        (jsonDecode(tripJson) as List<dynamic>).map(
          (item) => WakeTripRecord.fromJson(item as Map<String, dynamic>),
        ),
      );
    }

    final searchCacheJson = _preferences!.getString(_searchCacheKey);
    if (searchCacheJson != null) {
      final cached = jsonDecode(searchCacheJson) as Map<String, dynamic>;
      for (final entry in cached.entries) {
        _placeSearchCache[entry.key] = (entry.value as List<dynamic>)
            .map(
              (item) => WakeDestination.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }
    }

    final settings = _preferences!.getString(_settingsKey);
    if (settings != null) {
      final values = jsonDecode(settings) as Map<String, dynamic>;
      radiusMeters = values['radiusMeters'] as int? ?? radiusMeters;
      warningDistanceMeters =
          values['warningDistanceMeters'] as int? ?? warningDistanceMeters;
      vibrationEnabled = values['vibrationEnabled'] as bool? ?? true;
      repeatAlarm = values['repeatAlarm'] as bool? ?? true;
      snoozeMinutes = values['snoozeMinutes'] as int? ?? snoozeMinutes;
      alarmSound = values['alarmSound'] as String? ?? alarmSound;
      customAlarmSoundPath = values['customAlarmSoundPath'] as String?;
      offlineMode = values['offlineMode'] as bool? ?? offlineMode;
      useMetricUnits = values['useMetricUnits'] as bool? ?? useMetricUnits;
      batteryTipsEnabled =
          values['batteryTipsEnabled'] as bool? ?? batteryTipsEnabled;
    }

    await _notifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    notificationsEnabled =
        await _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.areNotificationsEnabled() ??
        false;
    locationServicesEnabled = await Geolocator.isLocationServiceEnabled();
    final permission = await Geolocator.checkPermission();
    locationPermissionStatus = permission.name;
    notifyListeners();
  }

  /// Searches for places and caches the results.
  Future<List<WakeDestination>> searchPlaces(String query) async {
    final term = query.trim();
    if (term.length < 3) return const [];
    final cacheKey = term.toLowerCase();
    final cached = _placeSearchCache[cacheKey];
    if (cached != null) return cached;

    final now = DateTime.now();
    final nextAllowed = _nextPlaceSearchAt ?? now;
    _nextPlaceSearchAt = nextAllowed.add(const Duration(seconds: 1));
    final wait = nextAllowed.difference(now);
    if (wait > Duration.zero) await Future<void>.delayed(wait);

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': term,
        'format': 'jsonv2',
        'limit': '6',
      });
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.userAgentHeader, 'WakeWay/1.0 Android');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close().timeout(
        const Duration(seconds: 12),
      );
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('Place search returned ${response.statusCode}.');
      }
      final body = await response.transform(utf8.decoder).join();
      final results = (jsonDecode(body) as List<dynamic>)
          .map(
            (item) =>
                WakeDestination.fromSearchResult(item as Map<String, dynamic>),
          )
          .toList();
      _placeSearchCache[cacheKey] = results;
      while (_placeSearchCache.length > 50) {
        _placeSearchCache.remove(_placeSearchCache.keys.first);
      }
      await _preferences?.setString(
        _searchCacheKey,
        jsonEncode(
          _placeSearchCache.map(
            (key, places) =>
                MapEntry(key, places.map((place) => place.toJson()).toList()),
          ),
        ),
      );
      return results;
    } finally {
      client.close(force: true);
    }
  }

  /// Gets the device's current location.
  Future<Position> locateOnce() async {
    await _ensureLocationPermission();
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
    currentPosition = position;
    locationServicesEnabled = true;
    lastError = null;
    notifyListeners();
    return position;
  }

  /// Updates the location permission and service status.
  Future<void> refreshPermissionStatus() async {
    locationServicesEnabled = await Geolocator.isLocationServiceEnabled();
    locationPermissionStatus = (await Geolocator.checkPermission()).name;
    notifyListeners();
  }

  /// Requests permission to show notifications.
  Future<void> requestNotificationPermission() async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    notificationsEnabled =
        await android?.requestNotificationsPermission() ?? true;
    notifyListeners();
  }

  /// Starts monitoring a trip and its alarm point.
  Future<void> startTrip({
    required WakeDestination destination,
    required WakeTripOptions options,
    double? alarmLat,
    double? alarmLon,
  }) async {
    if (isMonitoring) throw StateError('A trip is already being monitored.');
    await _ensureLocationPermission();
    await requestNotificationPermission();
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );

    activeDestination = destination;
    alarmLatitude = alarmLat ?? destination.latitude;
    alarmLongitude = alarmLon ?? destination.longitude;
    radiusMeters = options.radiusMeters;
    warningDistanceMeters = options.warningDistanceMeters;
    vibrationEnabled = options.vibration;
    repeatAlarm = options.repeatAlarm;
    snoozeMinutes = options.snoozeMinutes;
    alarmSound = options.alarmSound;
    customAlarmSoundPath = options.alarmSoundPath;
    currentPosition = position;
    distanceToAlarmMeters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      alarmLatitude,
      alarmLongitude,
    );
    tripStartedAt = DateTime.now();
    isMonitoring = true;
    alarmIsRinging = false;
    alarmIsSnoozed = false;
    warningWasShown = false;
    _alarmTriggeredInTrip = false;
    lastError = null;
    await _saveSettings();
    notifyListeners();

    final LocationSettings settings =
        defaultTargetPlatform == TargetPlatform.android
        ? AndroidSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
            intervalDuration: const Duration(seconds: 5),
            foregroundNotificationConfig: const ForegroundNotificationConfig(
              notificationTitle: 'WakeWay is monitoring your trip',
              notificationText: 'Location is used to alert you near your stop.',
              notificationChannelName: 'Trip monitoring',
              enableWakeLock: true,
              setOngoing: true,
            ),
          )
        : const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          );
    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: settings).listen(
          _onPosition,
          onError: (Object error) {
            lastError = 'GPS updates stopped: $error';
            notifyListeners();
          },
        );
    _onPosition(position);
  }

  /// Updates distance and checks whether to show a warning or trigger the alarm.
  void _onPosition(Position position) {
    if (!isMonitoring || activeDestination == null) return;
    currentPosition = position;
    distanceToAlarmMeters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      alarmLatitude,
      alarmLongitude,
    );
    final distance = distanceToAlarmMeters!;
    if (!warningWasShown &&
        distance <= warningDistanceMeters &&
        distance > radiusMeters) {
      warningWasShown = true;
      unawaited(_showProximityNotification(distance));
    }
    if (!alarmIsRinging && !alarmIsSnoozed && distance <= radiusMeters) {
      unawaited(_ringAlarm());
    }
    notifyListeners();
  }

  /// Shows a notification when the destination is getting close.
  Future<void> _showProximityNotification(double distance) async {
    try {
      await _notifications.show(
        id: 701,
        title: 'Your stop is getting close',
        body:
            '${_formatDistance(distance)} from ${activeDestination?.name ?? 'your destination'}',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'wakeway_proximity',
            'Approaching destination',
            channelDescription: 'A heads up before your WakeWay alarm point.',
            importance: Importance.high,
            priority: Priority.high,
            enableVibration: true,
          ),
        ),
      );
    } on Object catch (error) {
      lastError = 'Could not show the proximity notification: $error';
      notifyListeners();
    }
  }

  /// Starts the alarm sound, vibration, and notification.
  Future<void> _ringAlarm() async {
    alarmIsRinging = true;
    alarmIsSnoozed = false;
    _alarmTriggeredInTrip = true;
    alarmEventCount++;
    notifyListeners();
    if (vibrationEnabled) HapticFeedback.vibrate();
    try {
      await _notifications.show(
        id: 702,
        title: 'WakeWay: your stop is near',
        body:
            'Wake up and get ready to get off at ${activeDestination?.name ?? 'your stop'}.',
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'wakeway_alarm_v2',
            'WakeWay alarm',
            channelDescription:
                'Sound and vibration when you approach your stop.',
            importance: Importance.max,
            priority: Priority.max,
            category: AndroidNotificationCategory.alarm,
            fullScreenIntent: false,
            enableVibration: vibrationEnabled,
            vibrationPattern: vibrationEnabled
                ? Int64List.fromList([0, 700, 350, 700, 350, 1000])
                : null,
            playSound: false,
            ongoing: true,
            autoCancel: false,
          ),
        ),
      );
    } on Object catch (error) {
      lastError = 'Could not show the alarm notification: $error';
      notifyListeners();
    }
    try {
      await _alarmPlayer.setReleaseMode(
        repeatAlarm ? ReleaseMode.loop : ReleaseMode.stop,
      );
      final source = customAlarmSoundPath == null
          ? AssetSource(
              alarmSound == 'Classic alarm'
                  ? 'audio/classic_alarm.wav'
                  : 'audio/wake_alarm.wav',
            )
          : DeviceFileSource(customAlarmSoundPath!);
      await _alarmPlayer.play(
        source,
        ctx: AudioContext(
          android: const AudioContextAndroid(
            usageType: AndroidUsageType.alarm,
            contentType: AndroidContentType.sonification,
            stayAwake: true,
            audioFocus: AndroidAudioFocus.gain,
          ),
        ),
      );
    } on Object catch (error) {
      lastError = 'Could not play the alarm sound: $error';
      notifyListeners();
    }
  }

  /// Pauses the alarm and schedules it to ring again.
  Future<void> snoozeAlarm() async {
    if (!alarmIsRinging) return;
    await _alarmPlayer.stop();
    await _notifications.cancel(id: 702);
    alarmIsRinging = false;
    alarmIsSnoozed = true;
    _snoozeTimer?.cancel();
    _snoozeTimer = Timer(Duration(minutes: snoozeMinutes), () {
      if (isMonitoring && alarmIsSnoozed) unawaited(_ringAlarm());
    });
    notifyListeners();
  }

  /// Stops the alarm by ending the trip.
  Future<void> stopAlarm() => stopTrip(alarmTriggered: true);

  /// Stops monitoring and saves the trip record.
  Future<void> stopTrip({bool alarmTriggered = false}) async {
    if (!isMonitoring) return;
    isMonitoring = false;
    _snoozeTimer?.cancel();
    _snoozeTimer = null;
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    await _alarmPlayer.stop();
    await _notifications.cancel(id: 701);
    await _notifications.cancel(id: 702);
    final startedAt = tripStartedAt;
    final destination = activeDestination;
    if (startedAt != null && destination != null) {
      _trips.insert(
        0,
        WakeTripRecord(
          destination: destination.name,
          startedAt: startedAt,
          endedAt: DateTime.now(),
          alarmTriggered: alarmTriggered || _alarmTriggeredInTrip,
        ),
      );
      if (_trips.length > 100) _trips.removeRange(100, _trips.length);
      await _saveTrips();
    }
    alarmIsRinging = false;
    alarmIsSnoozed = false;
    _alarmTriggeredInTrip = false;
    activeDestination = null;
    tripStartedAt = null;
    distanceToAlarmMeters = null;
    notifyListeners();
  }

  /// Changes the alarm distance radius.
  Future<void> setRadius(int value) async {
    radiusMeters = value;
    await _saveSettings();
    notifyListeners();
  }

  /// Changes how far away the approach warning appears.
  Future<void> setWarningDistance(double kilometers) async {
    warningDistanceMeters = (kilometers * 1000).round();
    await _saveSettings();
    notifyListeners();
  }

  /// Selects a built-in alarm sound.
  Future<void> setAlarmSound(String value) async {
    final previousPath = customAlarmSoundPath;
    alarmSound = value;
    customAlarmSoundPath = null;
    await _saveSettings();
    await _removeUnusedAlarmSound(previousPath);
    notifyListeners();
  }

  /// Opens device music selection.
  Future<String?> pickDeviceMusic() => _pickCustomAlarmSound('pickDeviceMusic');

  /// Opens system ringtone selection.
  Future<String?> pickSystemRingtone() =>
      _pickCustomAlarmSound('pickSystemRingtone');

  /// Handles audio selection and saves the chosen sound.
  Future<String?> _pickCustomAlarmSound(String method) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      throw UnsupportedError('Device audio selection is available on Android.');
    }
    if (alarmIsRinging) {
      throw StateError('Stop the active alarm before changing its sound.');
    }
    final previousPath = customAlarmSoundPath;
    final selection = await _audioPickerChannel.invokeMapMethod<String, String>(
      method,
    );
    if (selection == null) return null;
    final path = selection['path'];
    final name = selection['name'];
    if (path == null || path.isEmpty || name == null || name.isEmpty) {
      throw StateError('The selected audio could not be loaded.');
    }
    alarmSound = name;
    customAlarmSoundPath = path;
    await _saveSettings();
    await _removeUnusedAlarmSound(previousPath);
    notifyListeners();
    return name;
  }

  /// Deletes a previously selected audio file if it is no longer used.
  Future<void> _removeUnusedAlarmSound(String? path) async {
    if (path == null || alarmIsRinging) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // The new selection is already saved; a stale copy can be cleaned later.
    }
  }

  /// Turns alarm vibration on or off.
  Future<void> setVibration(bool value) async {
    vibrationEnabled = value;
    await _saveSettings();
    notifyListeners();
  }

  /// Turns alarm sound repetition on or off.
  Future<void> setRepeatAlarm(bool value) async {
    repeatAlarm = value;
    await _saveSettings();
    notifyListeners();
  }

  /// Changes the snooze time.
  Future<void> setSnoozeDuration(int value) async {
    snoozeMinutes = value;
    await _saveSettings();
    notifyListeners();
  }

  /// Saves the offline mode setting.
  Future<void> setOfflineMode(bool value) async {
    offlineMode = value;
    await _saveSettings();
    notifyListeners();
  }

  /// Chooses metric or imperial distance units.
  Future<void> setMetricUnits(bool value) async {
    useMetricUnits = value;
    await _saveSettings();
    notifyListeners();
  }

  /// Turns battery tips on or off.
  Future<void> setBatteryTipsEnabled(bool value) async {
    batteryTipsEnabled = value;
    await _saveSettings();
    notifyListeners();
  }

  /// Formats a distance using the selected units.
  String formatDistance(double? meters) {
    if (meters == null) return 'Waiting for GPS';
    if (!useMetricUnits) {
      final miles = meters / 1609.344;
      return miles >= .1
          ? '${miles.toStringAsFixed(1)} mi'
          : '${(meters * 3.28084).round()} ft';
    }
    return meters >= 1000
        ? '${(meters / 1000).toStringAsFixed(1)} km'
        : '${meters.round()} m';
  }

  /// Formats a distance for internal use.
  String _formatDistance(double meters) => formatDistance(meters);

  /// Checks location services and requests permission when needed.
  Future<void> _ensureLocationPermission() async {
    locationServicesEnabled = await Geolocator.isLocationServiceEnabled();
    if (!locationServicesEnabled) {
      final opened = await Geolocator.openLocationSettings();
      if (!opened) throw StateError('Turn on device location to start a trip.');
      locationServicesEnabled = await Geolocator.isLocationServiceEnabled();
      if (!locationServicesEnabled) {
        throw StateError('Turn on device location to start a trip.');
      }
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    locationPermissionStatus = permission.name;
    if (permission == LocationPermission.denied) {
      throw StateError('Allow location access to monitor your trip.');
    }
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      throw StateError(
        'Allow location access in app settings, then try again.',
      );
    }
  }

  /// Saves trip records to local preferences.
  Future<void> _saveTrips() async => _preferences?.setString(
    _tripsKey,
    jsonEncode(_trips.map((item) => item.toJson()).toList()),
  );

  /// Saves app settings to local preferences.
  Future<void> _saveSettings() async => _preferences?.setString(
    _settingsKey,
    jsonEncode({
      'radiusMeters': radiusMeters,
      'warningDistanceMeters': warningDistanceMeters,
      'vibrationEnabled': vibrationEnabled,
      'repeatAlarm': repeatAlarm,
      'snoozeMinutes': snoozeMinutes,
      'alarmSound': alarmSound,
      'customAlarmSoundPath': customAlarmSoundPath,
      'offlineMode': offlineMode,
      'useMetricUnits': useMetricUnits,
      'batteryTipsEnabled': batteryTipsEnabled,
    }),
  );

  /// Cleans up location, timer, and audio resources.
  @override
  void dispose() {
    _positionSubscription?.cancel();
    _snoozeTimer?.cancel();
    _alarmPlayer.dispose();
    super.dispose();
  }
}
