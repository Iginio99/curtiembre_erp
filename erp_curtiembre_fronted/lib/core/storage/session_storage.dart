import 'dart:convert';

import 'package:erp_curtiembre_fronted/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionStorage {
  SessionStorage(this._secureStorage);

  static const String _sessionKey = 'erp_curtiembre_session';

  final FlutterSecureStorage _secureStorage;

  Future<void> saveSession(AuthSession session) {
    return _secureStorage.write(
      key: _sessionKey,
      value: jsonEncode(session.toMap()),
    );
  }

  Future<AuthSession?> readSession() async {
    final value = await _secureStorage.read(key: _sessionKey);
    if (value == null || value.isEmpty) {
      return null;
    }

    return AuthSession.fromMap(jsonDecode(value) as Map<String, dynamic>);
  }

  Future<String?> readSessionToken() async {
    final session = await readSession();
    return session?.sessionToken;
  }

  Future<void> clearSession() {
    return _secureStorage.delete(key: _sessionKey);
  }
}
