import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../analytics_names.dart';
import '../api/api_error.dart';
import '../auth/token_store.dart';
import '../providers.dart';

/// Firebase is optional (QUESTIONS M16): without google-services.json the app
/// runs normally and push/crash/analytics report "not set up".
class FirebaseState {
  FirebaseState._();
  static bool ready = false;

  /// Called after the first frame so it never slows the cold start.
  static Future<bool> init() async {
    if (ready) return true;
    try {
      await Firebase.initializeApp();
      ready = true;
      if (!kDebugMode) {
        FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
        PlatformDispatcher.instance.onError = (e, s) {
          FirebaseCrashlytics.instance.recordError(e, s, fatal: true);
          return true;
        };
      }
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
    } catch (_) {
      ready = false;
    }
    return ready;
  }
}

/// Anonymous screen and feature events only (QUESTIONS M15), with an off switch.
class Analytics {
  Analytics(this._store);
  final TokenStore _store;
  bool enabled = true;

  static const _key = 'analytics_enabled';

  Future<void> load() async => enabled = (await _store.read(_key)) != '0';

  Future<void> setEnabled(bool v) async {
    enabled = v;
    await _store.write(_key, v ? '1' : '0');
    if (FirebaseState.ready) await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(v);
  }

  /// Route paths without ids: /r/12/dishes/5 → /r/:id/dishes/:id.
  static String screenName(String path) => screenNameOf(path);

  void screen(String path) {
    if (!enabled || !FirebaseState.ready) return;
    unawaited(FirebaseAnalytics.instance.logScreenView(screenName: screenName(path)).catchError((_) {}));
  }

  void event(String name, [Map<String, Object>? params]) {
    if (!enabled || !FirebaseState.ready) return;
    unawaited(FirebaseAnalytics.instance.logEvent(name: name, parameters: params).catchError((_) {}));
  }
}

final analyticsProvider = Provider<Analytics>((ref) => Analytics(ref.watch(tokenStoreProvider)));

/// Server errors (5xx) as non-fatal reports, no personal data.
void reportNonFatal(Object error, StackTrace stack) {
  if (!FirebaseState.ready || kDebugMode) return;
  final e = ApiError.from(error);
  if (e.kind != ApiErrorKind.server && e.kind != ApiErrorKind.unknown) return;
  unawaited(FirebaseCrashlytics.instance.recordError(error, stack, reason: 'api ${e.status}', fatal: false));
}
