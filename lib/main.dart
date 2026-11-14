import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app/app.dart';
import 'app/env.dart';
import 'core/auth/auth_repository.dart';
import 'core/auth/token_store.dart';
import 'core/cache/cache_db.dart';
import 'core/cache/swr.dart';
import 'core/platform/app_lock.dart';
import 'core/platform/firebase.dart';
import 'core/platform/push.dart';
import 'core/platform/updates.dart';
import 'core/providers.dart';
import 'core/app_config.dart';

/// Cold start (PLAN.md §10): nothing waits for the network before the first
/// frame — token, last `/me` and cached screens come from the device.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = SecureTokenStore();
  final server = Env.canChangeServer ? (await store.read(TokenKeys.server) ?? Env.apiBaseUrl) : Env.apiBaseUrl;
  final info = await PackageInfo.fromPlatform();
  // No automatic provider retry: dio retries the network, screens offer "Try again".
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      tokenStoreProvider.overrideWithValue(store),
      cacheDbProvider.overrideWithValue(CacheDb()),
      serverProvider.overrideWithValue(server),
      appVersionProvider.overrideWithValue('${info.version}+${info.buildNumber}'),
      deviceNameProvider.overrideWithValue(await _deviceName()),
      platformNameProvider.overrideWithValue(Platform.isIOS ? 'ios' : 'android'),
    ],
  );
  await Future.wait([
    container.read(sessionProvider.notifier).restore(),
    container.read(appLockProvider.notifier).load(),
    container.read(analyticsProvider).load(),
  ]);
  runApp(UncontrolledProviderScope(container: container, child: const MenuAdminApp()));

  // After the first frame: Firebase, push, start-up settings, in-app update.
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    container.listen(cachedProvider('mobile/config'), (_, _) {});
    await FirebaseState.init();
    final push = container.read(pushServiceProvider);
    void startPush() => unawaited(push.start());
    if (container.read(sessionProvider).status == SessionStatus.signedIn) startPush();
    container.listen(sessionProvider.select((s) => s.status), (prev, next) {
      if (next == SessionStatus.signedIn && prev != SessionStatus.signedIn) startPush();
    });
    final review = ReviewPrompt(store);
    await review.recordSession();
    final config = container.read(appConfigProvider);
    final mustUpdate = config != null && compareVersions(info.version, config.minVersion) < 0;
    unawaited(checkPlayUpdate(mustUpdate: mustUpdate));
  });
}

/// "Samsung SM-A546E" — shown in Profile › Devices.
Future<String> _deviceName() async {
  try {
    final info = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final a = await info.androidInfo;
      final brand = a.manufacturer.isEmpty ? '' : '${a.manufacturer[0].toUpperCase()}${a.manufacturer.substring(1)} ';
      return '$brand${a.model}'.trim();
    }
    if (Platform.isIOS) return (await info.iosInfo).name;
  } catch (_) {}
  return kIsWeb ? 'Browser' : (Platform.isIOS ? 'iPhone' : 'Android phone');
}
