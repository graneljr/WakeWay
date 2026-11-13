import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:wakeway/core/database/sqlite_helper.dart';
import 'package:wakeway/features/auth/repositories/authentication_repository.dart';
import 'package:wakeway/features/map/models/wake_destination.dart';
import 'package:wakeway/features/trips/models/trips.dart';
import 'package:wakeway/features/trips/models/wake_trip_options.dart';
import 'package:wakeway/features/trips/models/wake_trip_record.dart';

class WakeWayViewModel extends ChangeNotifier {
  WakeWayViewModel({
    String? Function()? currentUserId,
    AuthenticationRepository? authenticationRepository,
  }) : _currentUserId = currentUserId,
       _authenticationRepository =
           authenticationRepository ?? AuthenticationRepository();

  static const _tripsKey = 'wakeway.trips.v1';
  static const _settingsKey = 'wakeway.settings.v1';
  static const _searchCacheKey = 'wakeway.placeSearchCache.v1';

  final String? Function()? _currentUserId;
  final AuthenticationRepository _authenticationRepository;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  final AudioPlayer _alarmPlayer = AudioPlayer();

  static const MethodChannel _audioPickerChannel = MethodChannel(
    'com.example.wakeway/audio_picker',
  );

  static const Uuid _uuid = Uuid();

  final SQLiteHelper _database = SQLiteHelper.instance;

  final List<WakeTripRecord> _trips = [];
  final List<WakeTrip> _unfinishedTrips = [];

  final Map<String, List<WakeDestination>> _placeSearchCache = {};

  StreamSubscription<Position>? _positionSubscription;
  Timer? _snoozeTimer;

  SharedPreferences? _preferences;
  DateTime? _nextPlaceSearchAt;

  WakeTrip? _activeTrip;

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

  // ---------------------------------------------------------------------------
  // GETTERS
  // ---------------------------------------------------------------------------

  List<WakeTripRecord> get trips => List.unmodifiable(_trips);
  List<WakeTrip> get unfinishedTrips => List.unmodifiable(_unfinishedTrips);

  AuthenticationRepository get authenticationRepository =>
      _authenticationRepository;

  String? get currentUserId {
    if (_currentUserId != null) return _currentUserId();
    return _authenticationRepository.currentUserId;
  }

  bool get isAlarmActive => alarmIsRinging || alarmIsSnoozed;

  String? get activeTripId => _activeTrip?.id;

  bool get locationReady =>
      locationServicesEnabled &&
      (locationPermissionStatus == 'whileInUse' ||
          locationPermissionStatus == 'always');

  String get activeDestinationName =>
      _activeTrip?.destinationName ??
      activeDestination?.name ??
      'Custom location';

  // ---------------------------------------------------------------------------
  // INITIALIZATION
  // ---------------------------------------------------------------------------

  Future<void> initialize() async {
    _preferences = await SharedPreferences.getInstance();

    await _loadSearchCache();
    await _loadSettings();
    await _loadTripHistory();
    await _loadUnfinishedTrips();

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

  Future<void> _loadTripHistory() async {
    final userId = currentUserId;

    if (userId == null) return;

    final rows = await _database.getTrips(userId);

    _trips.clear();

    for (final row in rows) {
      final completedAt = row['completed_at'];

      if (completedAt == null) continue;

      _trips.add(
        WakeTripRecord(
          destination: row['destination_name'] as String,
          startedAt: DateTime.parse(row['started_at'] as String),
          endedAt: DateTime.parse(completedAt as String),
          alarmTriggered: row['alarm_triggered'] == 1,
        ),
      );
    }

    if (_trips.length > 100) {
      _trips.removeRange(100, _trips.length);
    }
  }

  Future<void> _loadUnfinishedTrips() async {
    final userId = currentUserId;
    if (userId == null) return;

    final rows = await _database.getUnfinishedTrips(userId);
    _unfinishedTrips
      ..clear()
      ..addAll(rows.map(WakeTrip.fromLocalJson));
  }

  Future<void> refreshLocalTripData() async {
    await _loadTripHistory();
    await _loadUnfinishedTrips();
    notifyListeners();
  }

  Future<void> _loadSearchCache() async {
    final searchCacheJson = _preferences?.getString(_searchCacheKey);

    if (searchCacheJson == null) return;

    final cached = jsonDecode(searchCacheJson) as Map<String, dynamic>;

    for (final entry in cached.entries) {
      _placeSearchCache[entry.key] = (entry.value as List<dynamic>)
          .map((item) => WakeDestination.fromJson(item as Map<String, dynamic>))
          .toList();
    }
  }

  Future<void> _loadSettings() async {
    final settingsJson = _preferences?.getString(_settingsKey);

    if (settingsJson == null) return;

    final values = jsonDecode(settingsJson) as Map<String, dynamic>;

    radiusMeters = values['radiusMeters'] as int? ?? radiusMeters;

    warningDistanceMeters =
        values['warningDistanceMeters'] as int? ?? warningDistanceMeters;

    vibrationEnabled = values['vibration_enabled'] as bool? ?? vibrationEnabled;

    repeatAlarm = values['repeat_alarm'] as bool? ?? repeatAlarm;

    snoozeMinutes = values['snooze_minutes'] as int? ?? snoozeMinutes;

    alarmSound = values['alarm_sound'] as String? ?? alarmSound;

    customAlarmSoundPath = values['custom_alarm_sound_path'] as String?;

    offlineMode = values['offline_mode'] as bool? ?? offlineMode;

    useMetricUnits = values['use_metric_units'] as bool? ?? useMetricUnits;

    batteryTipsEnabled =
        values['batteryTipsEnabled'] as bool? ?? batteryTipsEnabled;
  }

  // ---------------------------------------------------------------------------
  // PLACE SEARCH
  // ---------------------------------------------------------------------------

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

    if (wait > Duration.zero) {
      await Future<void>.delayed(wait);
    }

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

  // ---------------------------------------------------------------------------
  // LOCATION
  // ---------------------------------------------------------------------------

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

  Future<void> refreshPermissionStatus() async {
    locationServicesEnabled = await Geolocator.isLocationServiceEnabled();

    locationPermissionStatus = (await Geolocator.checkPermission()).name;

    notifyListeners();
  }

  Future<void> requestNotificationPermission() async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    notificationsEnabled =
        await android?.requestNotificationsPermission() ?? true;

    notifyListeners();
  }

  Future<void> _ensureLocationPermission() async {
    locationServicesEnabled = await Geolocator.isLocationServiceEnabled();

    if (!locationServicesEnabled) {
      final opened = await Geolocator.openLocationSettings();

      if (!opened) {
        throw StateError('Turn on device location to start a trip.');
      }

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

  // ---------------------------------------------------------------------------
  // START TRIP
  // ---------------------------------------------------------------------------

  /// Starts a trip using either a saved destination or custom map location.
  ///
  /// [destination] provides the displayed location information.
  /// [savedDestinationId] should only be provided when the user selected
  /// an actual saved destination.
  ///
  /// For a custom location, leave [savedDestinationId] null and provide
  /// [alarmLat] and [alarmLon].
  Future<void> startTrip({
    WakeDestination? destination,
    required WakeTripOptions options,
    String? savedDestinationId,
    double? alarmLat,
    double? alarmLon,
    String? locationName,
    String? address,
  }) async {
    if (isMonitoring) {
      throw StateError('A trip is already being monitored.');
    }

    final userId = currentUserId;

    if (userId == null) {
      throw StateError('Sign in before starting a trip.');
    }

    // Resolve the alarm coordinates.
    final double? resolvedLat = options.useAdvancePoint
        ? options.advanceLatitude
        : (alarmLat ?? destination?.latitude);

    final double? resolvedLon = options.useAdvancePoint
        ? options.advanceLongitude
        : (alarmLon ?? destination?.longitude);

    if (resolvedLat == null || resolvedLon == null) {
      throw ArgumentError('A valid alarm location must be provided.');
    }

    if (options.useAdvancePoint &&
        (options.advanceLatitude == null || options.advanceLongitude == null)) {
      throw ArgumentError('Select a valid advance alarm point.');
    }

    await _ensureLocationPermission();
    await requestNotificationPermission();

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );

    final now = DateTime.now();

    final tripName = locationName ?? destination?.name ?? 'Custom location';

    final tripAddress = address ?? destination?.address;

    final trip = WakeTrip(
      id: _uuid.v4(),
      userId: userId,
      destinationId: savedDestinationId,
      destinationName: tripName,
      destinationAddress: tripAddress,
      alarmLatitude: resolvedLat,
      alarmLongitude: resolvedLon,
      radiusMeters: options.radiusMeters,
      warningDistanceMeters: options.warningDistanceMeters,
      vibrationEnabled: options.vibration,
      repeatAlarm: options.repeatAlarm,
      snoozeMinutes: options.snoozeMinutes,
      alarmSound: options.alarmSound,
      customAlarmSoundPath: options.alarmSoundPath,
      useAdvancePoint: options.useAdvancePoint,
      status: 'active',
      startedAt: now,
      alarmTriggered: false,
      updatedAt: now,
    );

    // Save trip and sync queue atomically before starting GPS monitoring.
    await _database.insertTrip(
      trip: trip.toLocalJson(),
      cloudPayload: trip.toCloudJson(),
      queueId: _uuid.v4(),
    );

    _unfinishedTrips.insert(0, trip);
    await _startMonitoring(trip, destination: destination, position: position);
  }

  Future<void> resumeTrip(String tripId) async {
    if (isMonitoring) {
      if (_activeTrip?.id == tripId) return;
      throw StateError('Another trip is already being monitored.');
    }

    final tripIndex = _unfinishedTrips.indexWhere((trip) => trip.id == tripId);
    if (tripIndex == -1) {
      throw StateError('This trip is no longer available to resume.');
    }

    final trip = _unfinishedTrips[tripIndex];
    await _ensureLocationPermission();
    await requestNotificationPermission();

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );

    final resumedTrip = WakeTrip(
      id: trip.id,
      userId: trip.userId,
      destinationId: trip.destinationId,
      destinationName: trip.destinationName,
      destinationAddress: trip.destinationAddress,
      alarmLatitude: trip.alarmLatitude,
      alarmLongitude: trip.alarmLongitude,
      radiusMeters: trip.radiusMeters,
      warningDistanceMeters: trip.warningDistanceMeters,
      vibrationEnabled: trip.vibrationEnabled,
      repeatAlarm: trip.repeatAlarm,
      snoozeMinutes: trip.snoozeMinutes,
      alarmSound: trip.alarmSound,
      customAlarmSoundPath: trip.customAlarmSoundPath,
      useAdvancePoint: trip.useAdvancePoint,
      status: 'active',
      startedAt: trip.startedAt,
      completedAt: null,
      alarmTriggered: trip.alarmTriggered,
      updatedAt: DateTime.now().toUtc(),
    );

    await _database.markTripActive(
      tripId: resumedTrip.id,
      userId: resumedTrip.userId,
      updatedAt: resumedTrip.updatedAt.toIso8601String(),
      cloudPayload: resumedTrip.toCloudJson(),
      queueId: _uuid.v4(),
    );

    _unfinishedTrips[tripIndex] = resumedTrip;
    await _startMonitoring(
      resumedTrip,
      destination: _destinationFromTrip(resumedTrip),
      position: position,
    );
  }

  Future<void> _startMonitoring(
    WakeTrip trip, {
    required WakeDestination? destination,
    required Position position,
  }) async {
    _activeTrip = trip;
    activeDestination = destination ?? _destinationFromTrip(trip);

    alarmLatitude = trip.alarmLatitude;
    alarmLongitude = trip.alarmLongitude;
    radiusMeters = trip.radiusMeters;
    warningDistanceMeters = trip.warningDistanceMeters;
    vibrationEnabled = trip.vibrationEnabled;
    repeatAlarm = trip.repeatAlarm;
    snoozeMinutes = trip.snoozeMinutes;
    alarmSound = trip.alarmSound;
    customAlarmSoundPath = trip.customAlarmSoundPath;
    currentPosition = position;

    distanceToAlarmMeters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      alarmLatitude,
      alarmLongitude,
    );
    tripStartedAt = trip.startedAt;
    isMonitoring = true;
    alarmIsRinging = false;
    alarmIsSnoozed = false;
    warningWasShown = false;
    _alarmTriggeredInTrip = trip.alarmTriggered;
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

    try {
      _positionSubscription =
          Geolocator.getPositionStream(locationSettings: settings).listen(
            _onPosition,
            onError: (Object error) {
              lastError = 'GPS updates stopped: $error';
              notifyListeners();
            },
          );
      _onPosition(position);
    } catch (error) {
      lastError = 'Could not start GPS monitoring: $error';
      isMonitoring = false;
      notifyListeners();
      rethrow;
    }
  }

  WakeDestination _destinationFromTrip(WakeTrip trip) => WakeDestination(
    id: trip.destinationId ?? trip.id,
    name: trip.destinationName,
    user_id: trip.userId,
    address: trip.destinationAddress ?? '',
    latitude: trip.alarmLatitude,
    longitude: trip.alarmLongitude,
  );

  // ---------------------------------------------------------------------------
  // GPS MONITORING
  // ---------------------------------------------------------------------------

  void _onPosition(Position position) {
    if (!isMonitoring) return;

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

  // ---------------------------------------------------------------------------
  // NOTIFICATIONS
  // ---------------------------------------------------------------------------

  Future<void> _showProximityNotification(double distance) async {
    try {
      await _notifications.show(
        id: 701,
        title: 'Your stop is getting close',
        body: '${_formatDistance(distance)} from $activeDestinationName',
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

  // ---------------------------------------------------------------------------
  // ALARM
  // ---------------------------------------------------------------------------

  Future<void> _ringAlarm() async {
    if (alarmIsRinging || !isMonitoring) return;

    alarmIsRinging = true;
    alarmIsSnoozed = false;

    _alarmTriggeredInTrip = true;
    alarmEventCount++;

    notifyListeners();

    if (vibrationEnabled) {
      HapticFeedback.vibrate();
    }

    try {
      await _notifications.show(
        id: 702,
        title: 'WakeWay: your stop is near',
        body: 'Wake up and get ready to get off at $activeDestinationName.',
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

  // ---------------------------------------------------------------------------
  // SNOOZE
  // ---------------------------------------------------------------------------

  Future<void> snoozeAlarm() async {
    if (!alarmIsRinging) return;

    await _alarmPlayer.stop();

    await _notifications.cancel(id: 702);

    alarmIsRinging = false;
    alarmIsSnoozed = true;

    _snoozeTimer?.cancel();

    _snoozeTimer = Timer(Duration(minutes: snoozeMinutes), () {
      if (isMonitoring && alarmIsSnoozed) {
        unawaited(_ringAlarm());
      }
    });

    notifyListeners();
  }

  Future<void> stopAlarm() => stopTrip(alarmTriggered: true);

  // ---------------------------------------------------------------------------
  // STOP TRIP
  // ---------------------------------------------------------------------------

  Future<void> stopTrip({bool alarmTriggered = false}) async {
    if (!isMonitoring || _activeTrip == null) return;

    final trip = _activeTrip!;

    isMonitoring = false;

    _snoozeTimer?.cancel();
    _snoozeTimer = null;

    await _positionSubscription?.cancel();
    _positionSubscription = null;

    await _alarmPlayer.stop();

    await _notifications.cancel(id: 701);
    await _notifications.cancel(id: 702);

    final triggered = alarmTriggered || _alarmTriggeredInTrip;

    final now = DateTime.now();

    // Build the completed cloud record.
    final completedTrip = WakeTrip(
      id: trip.id,
      userId: trip.userId,
      destinationId: trip.destinationId,
      destinationName: trip.destinationName,
      destinationAddress: trip.destinationAddress,
      alarmLatitude: trip.alarmLatitude,
      alarmLongitude: trip.alarmLongitude,
      radiusMeters: trip.radiusMeters,
      warningDistanceMeters: trip.warningDistanceMeters,
      vibrationEnabled: trip.vibrationEnabled,
      repeatAlarm: trip.repeatAlarm,
      snoozeMinutes: trip.snoozeMinutes,
      alarmSound: trip.alarmSound,
      customAlarmSoundPath: trip.customAlarmSoundPath,
      useAdvancePoint: trip.useAdvancePoint,
      status: 'completed',
      startedAt: trip.startedAt,
      completedAt: now,
      alarmTriggered: triggered,
      updatedAt: now,
    );

    // Update SQLite and queue the cloud update atomically.
    await _database.completeTrip(
      tripId: trip.id,
      cloudPayload: completedTrip.toCloudJson(),
      queueId: _uuid.v4(),
    );

    _trips.insert(
      0,
      WakeTripRecord(
        destination: trip.destinationName,
        startedAt: trip.startedAt,
        endedAt: now,
        alarmTriggered: triggered,
      ),
    );

    if (_trips.length > 100) {
      _trips.removeRange(100, _trips.length);
    }

    alarmIsRinging = false;
    alarmIsSnoozed = false;

    _alarmTriggeredInTrip = false;

    activeDestination = null;
    _activeTrip = null;
    _unfinishedTrips.removeWhere((unfinished) => unfinished.id == trip.id);

    tripStartedAt = null;
    distanceToAlarmMeters = null;

    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // APP SETTINGS
  // ---------------------------------------------------------------------------

  Future<void> setRadius(int value) async {
    radiusMeters = value;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setWarningDistance(double kilometers) async {
    warningDistanceMeters = (kilometers * 1000).round();
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setAlarmSound(String value) async {
    final previousPath = customAlarmSoundPath;

    alarmSound = value;
    customAlarmSoundPath = null;

    await _saveSettings();
    await _removeUnusedAlarmSound(previousPath);

    notifyListeners();
  }

  Future<String?> pickDeviceMusic() => _pickCustomAlarmSound('pickDeviceMusic');

  Future<String?> pickSystemRingtone() =>
      _pickCustomAlarmSound('pickSystemRingtone');

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

  Future<void> _removeUnusedAlarmSound(String? path) async {
    if (path == null || alarmIsRinging) return;

    try {
      final file = File(path);

      if (await file.exists()) {
        await file.delete();
      }
    } on FileSystemException {
      // A stale file can be cleaned up later.
    }
  }

  Future<void> setVibration(bool value) async {
    vibrationEnabled = value;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setRepeatAlarm(bool value) async {
    repeatAlarm = value;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setSnoozeDuration(int value) async {
    snoozeMinutes = value;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setOfflineMode(bool value) async {
    offlineMode = value;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setMetricUnits(bool value) async {
    useMetricUnits = value;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setBatteryTipsEnabled(bool value) async {
    batteryTipsEnabled = value;
    await _saveSettings();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // DISTANCE FORMATTING
  // ---------------------------------------------------------------------------

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

  String _formatDistance(double meters) => formatDistance(meters);

  // ---------------------------------------------------------------------------
  // SAVE SETTINGS
  // ---------------------------------------------------------------------------

  Future<void> _saveSettings() async {
    await _preferences?.setString(
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
  }

  // ---------------------------------------------------------------------------
  // DISPOSE
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _snoozeTimer?.cancel();
    _alarmPlayer.dispose();

    super.dispose();
  }
}
