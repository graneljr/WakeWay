import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakeway/features/destinations/repositories/destination_repository.dart';
import 'package:wakeway/features/map/models/wake_destination.dart';

class DestinationViewModel extends ChangeNotifier {
  DestinationViewModel({DestinationRepository? repository})
    : _repository = repository ?? DestinationRepository();

  static const _legacyDestinationsKey = 'wakeway.destinations.v1';

  final DestinationRepository _repository;
  List<WakeDestination> _destinations = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasInitialized = false;
  bool _disposed = false;
  String? _errorMessage;

  List<WakeDestination> get destinations => List.unmodifiable(_destinations);
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  WakeDestination? get defaultDestination =>
      _destinations.isEmpty ? null : _destinations.first;
  Future<void> initialize() async {
    if (_hasInitialized || _isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    _notifyListeners();

    try {
      _destinations = await _repository.getDestinations();

      final preferences = await SharedPreferences.getInstance();
      final legacyJson = preferences.getString(_legacyDestinationsKey);
      if (legacyJson != null) {
        final legacyItems = (jsonDecode(legacyJson) as List<dynamic>)
            .map(
              (item) => WakeDestination.fromJson(item as Map<String, dynamic>),
            )
            .toList(growable: false);
        await _repository.importLegacyDestinations(legacyItems);
        await preferences.remove(_legacyDestinationsKey);
        _destinations = await _repository.getDestinations();
      }

      _hasInitialized = true;
    } on Object catch (error) {
      _errorMessage = _messageFor(error);
    } finally {
      _isLoading = false;
      _notifyListeners();
    }
  }

  Future<bool> saveDestination(WakeDestination destination) =>
      _runMutation(() => _repository.saveDestination(destination));

  Future<bool> renameDestination(WakeDestination destination, String name) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || trimmedName == destination.name) {
      return Future.value(true);
    }
    return _runMutation(
      () => _repository.renameDestination(destination, trimmedName),
    );
  }

  Future<bool> removeDestination(WakeDestination destination) =>
      _runMutation(() => _repository.removeDestination(destination));

  Future<bool> _runMutation(Future<void> Function() mutation) async {
    if (_isSaving) return false;
    _isSaving = true;
    _errorMessage = null;
    _notifyListeners();

    try {
      await mutation();
      _destinations = await _repository.getDestinations();
      return true;
    } on Object catch (error) {
      _errorMessage = _messageFor(error);
      return false;
    } finally {
      _isSaving = false;
      _notifyListeners();
    }
  }

  String _messageFor(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  void _notifyListeners() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
