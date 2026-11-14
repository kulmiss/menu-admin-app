// Before/after screenshots for comparing with the web admin (redesign, 2026-11-14).
// `COMPARE_DIR=after flutter test --run-skipped -t compare --update-goldens test/compare` (Linux).
@Tags(['compare'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menu_admin/app/app.dart';
import 'package:menu_admin/app/router.dart';
import 'package:menu_admin/core/auth/token_store.dart';
import 'package:menu_admin/core/providers.dart';

import '../helpers/fake_api.dart';
import '../store/store_screenshots_test.dart' show demoRestaurant, phone, loadScreenshotFonts;

const dir = String.fromEnvironment('COMPARE_DIR', defaultValue: 'before');

Future<void> shot(WidgetTester tester, String path, String name, Brightness b, {bool signedIn = true}) async {
  tester.view.physicalSize = phone * 2.75;
  tester.view.devicePixelRatio = 2.75;
  tester.platformDispatcher.platformBrightnessTestValue = b;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  final store = MemoryTokenStore();
  if (signedIn) store.values[TokenKeys.token] = 'tok';
  final c = ProviderContainer(
    overrides: testOverrides(demoRestaurant(), store: store),
    retry: noRetry,
  );
  addTearDown(c.dispose);
  await tester.runAsync(() => c.read(sessionProvider.notifier).restore());
  await tester.pumpWidget(UncontrolledProviderScope(container: c, child: const MenuAdminApp()));
  await tester.pumpAndSettle();
  if (signedIn) {
    c.read(routerProvider).go(path);
    await tester.pumpAndSettle();
  }
  await expectLater(find.byType(MenuAdminApp), matchesGoldenFile('../../docs/screens/$dir/${name}_${b.name}.png'));
}

void main() {
  setUpAll(loadScreenshotFonts);
  for (final b in Brightness.values) {
    testWidgets('sign-in ${b.name}', (t) => shot(t, '/sign-in', 'sign_in', b, signedIn: false));
    testWidgets('home ${b.name}', (t) => shot(t, '/r/7', 'home', b));
    testWidgets('menu ${b.name}', (t) => shot(t, '/r/7/menu', 'menu', b));
    testWidgets('dish ${b.name}', (t) => shot(t, '/r/7/dishes/42', 'dish_edit', b));
    testWidgets('settings ${b.name}', (t) => shot(t, '/account/app', 'settings', b));
  }
}
