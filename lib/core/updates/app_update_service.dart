import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class AppUpdateRelease {
  const AppUpdateRelease({
    required this.version,
    required this.installedVersion,
    required this.apkUrl,
    required this.releaseUrl,
    required this.releaseNotes,
  });

  final String version;
  final String installedVersion;
  final Uri apkUrl;
  final Uri releaseUrl;
  final String releaseNotes;
}

class AppUpdateService {
  AppUpdateService({HttpClient? httpClient})
    : _httpClient = httpClient ?? HttpClient();

  static const _repository = String.fromEnvironment(
    'WAKEWAY_GITHUB_REPOSITORY',
  );
  static const _channel = MethodChannel('com.example.wakeway/app_updates');

  final HttpClient _httpClient;

  bool get isConfigured =>
      RegExp(r'^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$').hasMatch(_repository);

  Future<AppUpdateRelease?> checkForUpdate() async {
    if (!Platform.isAndroid) return null;
    if (!isConfigured) {
      throw StateError(
        'Set WAKEWAY_GITHUB_REPOSITORY to your public owner/repository name.',
      );
    }

    final installedVersion =
        await _channel.invokeMethod<String>('getAppVersion') ?? '0.0.0';
    final repositoryParts = _repository.split('/');
    final releaseUri = Uri.https(
      'api.github.com',
      '/repos/${repositoryParts[0]}/${repositoryParts[1]}/releases/latest',
    );

    final request = await _httpClient
        .getUrl(releaseUri)
        .timeout(const Duration(seconds: 20));
    request.headers
      ..set(HttpHeaders.acceptHeader, 'application/vnd.github+json')
      ..set(HttpHeaders.userAgentHeader, 'WakeWay Android updater');

    final response = await request.close().timeout(const Duration(seconds: 30));
    final responseBody = await utf8.decoder.bind(response).join();
    if (response.statusCode == HttpStatus.notFound) return null;
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        'GitHub returned HTTP ${response.statusCode} while checking releases.',
        uri: releaseUri,
      );
    }

    final data = jsonDecode(responseBody);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('GitHub returned an invalid release.');
    }

    final tagName = data['tag_name'];
    final releaseUrl = data['html_url'];
    final assets = data['assets'];
    if (tagName is! String || releaseUrl is! String || assets is! List) {
      throw const FormatException('GitHub release is missing required fields.');
    }

    final apkAsset = assets.cast<Object?>().firstWhere(
      (asset) =>
          asset is Map<String, dynamic> &&
          asset['name'] is String &&
          (asset['name'] as String).toLowerCase().endsWith('.apk') &&
          asset['browser_download_url'] is String,
      orElse: () => null,
    );
    if (apkAsset is! Map<String, dynamic>) {
      throw StateError('The latest GitHub release does not include an APK.');
    }

    final version = tagName.replaceFirst(RegExp(r'^[vV]'), '');
    if (_compareVersions(version, installedVersion) <= 0) return null;

    return AppUpdateRelease(
      version: version,
      installedVersion: installedVersion,
      apkUrl: Uri.parse(apkAsset['browser_download_url'] as String),
      releaseUrl: Uri.parse(releaseUrl),
      releaseNotes: data['body'] as String? ?? '',
    );
  }

  Future<bool> canInstallPackages() async =>
      await _channel.invokeMethod<bool>('canInstallPackages') ?? false;

  Future<void> openInstallPermissionSettings() =>
      _channel.invokeMethod<void>('openInstallPermissionSettings');

  Future<File> downloadApk(AppUpdateRelease release) async {
    final request = await _httpClient
        .getUrl(release.apkUrl)
        .timeout(const Duration(seconds: 20));
    request.headers.set(HttpHeaders.userAgentHeader, 'WakeWay Android updater');

    final response = await request.close().timeout(const Duration(seconds: 60));
    if (response.statusCode != HttpStatus.ok) {
      await response.drain<void>();
      throw HttpException(
        'Could not download the APK (HTTP ${response.statusCode}).',
        uri: release.apkUrl,
      );
    }

    final temporaryDirectory = await getTemporaryDirectory();
    final updatesDirectory = Directory(
      path.join(temporaryDirectory.path, 'wakeway_updates'),
    );
    await updatesDirectory.create(recursive: true);

    final safeVersion = release.version.replaceAll(
      RegExp(r'[^A-Za-z0-9._-]'),
      '_',
    );
    final apkFile = File(
      path.join(updatesDirectory.path, 'wakeway-$safeVersion.apk'),
    );
    await response.pipe(apkFile.openWrite());
    if (await apkFile.length() == 0) {
      await apkFile.delete();
      throw StateError('The downloaded APK is empty.');
    }
    return apkFile;
  }

  Future<void> openApkInstaller(File apkFile) =>
      _channel.invokeMethod<void>('installApk', {'path': apkFile.path});

  int _compareVersions(String first, String second) {
    List<int> parts(String value) {
      final normalized = value
          .trim()
          .split('+')
          .first
          .split('-')
          .first
          .replaceFirst(RegExp(r'^[vV]'), '');
      final result = normalized.split('.').map(int.tryParse).toList();
      if (result.isEmpty || result.any((part) => part == null)) {
        throw FormatException('Invalid app version: $value');
      }
      return result.cast<int>();
    }

    final firstParts = parts(first);
    final secondParts = parts(second);
    final length = firstParts.length > secondParts.length
        ? firstParts.length
        : secondParts.length;
    for (var index = 0; index < length; index++) {
      final firstPart = index < firstParts.length ? firstParts[index] : 0;
      final secondPart = index < secondParts.length ? secondParts[index] : 0;
      if (firstPart != secondPart) return firstPart.compareTo(secondPart);
    }
    return 0;
  }
}
