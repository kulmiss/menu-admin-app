import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../providers.dart';

/// Result of the first sign-in step.
sealed class LoginResult {}

class LoggedIn extends LoginResult {
  LoggedIn(this.token);
  final String token;
}

class NeedsTwoFactor extends LoginResult {
  NeedsTwoFactor(this.challenge);
  final String challenge;
}

/// Token sign-in (backend QUESTIONS #187).
class AuthRepository {
  AuthRepository(this._api, {required this.deviceName, required this.platform, required this.appVersion});

  final ApiClient _api;
  final String deviceName;
  final String platform;
  final String appVersion;

  /// Sign-in requests carry no token and no Idempotency-Key (the server keeps no answer with a token).
  static Options get _signIn => Options(extra: {'noIdempotency': true, 'noAuth': true});

  Map<String, dynamic> get _device => {'device_name': deviceName, 'platform': platform, 'app_version': appVersion.split('+').first};

  Future<LoginResult> login(String email, String password) async {
    final r = (await _api.post('mobile/auth/login', data: {'email': email.trim(), 'password': password, ..._device}, options: _signIn)) as Map;
    if (r['two_factor'] == true) return NeedsTwoFactor(r['challenge'] as String);
    return LoggedIn(r['token'] as String);
  }

  Future<String> twoFactor(String challenge, {String? code, String? recoveryCode}) async {
    final r = (await _api.post(
      'mobile/auth/two-factor',
      data: {'challenge': challenge, if (code != null) 'code': code.replaceAll(' ', ''), if (recoveryCode != null) 'recovery_code': recoveryCode.trim()},
    )) as Map;
    return r['token'] as String;
  }
}

/// Filled in main() with the real device name (package_info / platform).
final deviceNameProvider = Provider<String>((ref) => 'Android phone');
final platformNameProvider = Provider<String>((ref) => 'android');

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(apiProvider),
    deviceName: ref.watch(deviceNameProvider),
    platform: ref.watch(platformNameProvider),
    appVersion: ref.watch(appVersionProvider),
  ),
);
