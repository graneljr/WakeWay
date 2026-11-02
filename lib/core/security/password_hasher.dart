
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class PasswordHasher {
  static const int _iterations = 210000;
  static const int _saltLength = 16;
  static const int _keyLength = 32;

  List<int> _generateSalt() {
    final random = Random.secure();

    return List<int>.generate(
      _saltLength,
      (_) => random.nextInt(256),
    );
  }

  List<int> _deriveKey(String? password, List<int> salt) {
    final passwordBytes = utf8.encode(password ?? '');

    final hmac = Hmac(sha256, passwordBytes);

    final block = <int>[
      ...salt,
      0, 0, 0, 1,
    ];

    var u = hmac.convert(block).bytes;
    final result = List<int>.from(u);

    for (var i = 1; i < _iterations; i++) {
      u = hmac.convert(u).bytes;

      for (var j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }

    return result.sublist(0, _keyLength);
  }

 
  String hashPassword(String? password) {
    final salt = _generateSalt();
    final hash = _deriveKey(password, salt);

    return [
      'pbkdf2',
      'sha256',
      _iterations.toString(),
      base64Encode(salt),
      base64Encode(hash),
    ].join('\$');
  }

  bool verifyPassword(String password, String storedHash) {
    try {
      final parts = storedHash.split('\$');

      if (parts.length != 5 ||
          parts[0] != 'pbkdf2' ||
          parts[1] != 'sha256' ||
          int.parse(parts[2]) != _iterations) {
        return false;
      }

      final salt = base64Decode(parts[3]);
      final expectedHash = base64Decode(parts[4]);

      if (salt.length != _saltLength ||
          expectedHash.length != _keyLength) {
        return false;
      }

      final actualHash = _deriveKey(password, salt);

      return _constantTimeEquals(actualHash, expectedHash);
    } catch (_) {
      return false;
    }
  }

  /// Compare hashes without early exit on the first mismatch.
  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;

    var difference = 0;

    for (var i = 0; i < a.length; i++) {
      difference |= a[i] ^ b[i];
    }

    return difference == 0;
  }
}
