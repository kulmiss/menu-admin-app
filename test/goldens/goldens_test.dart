// Golden images of key screens: light/dark × phone/tablet (PLAN.md §11).
// Linux only (font rendering differs per OS); update with
// `flutter test --update-goldens test/goldens`.
@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menu_admin/core/auth/token_store.dart';
import 'package:menu_admin/core/providers.dart';
import 'package:menu_admin/features/auth/sign_in_screen.dart';
import 'package:menu_admin/features/restaurant/sold_out_screen.dart';

import '../helpers/fake_api.dart';
import '../widgets/flows.dart';

Future<void> _loadFonts() async {
  final inter = FontLoader('Inter');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    inter.addFont(rootBundle.load('assets/fonts/Inter-$w.ttf'));
  }
  await inter.load();
  final root = Platform.environment['FLUTTER_ROOT'] ?? '/opt/sdk/flutter';
  final icons = File('$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    await (FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())))).load();
  }
}

const sizes = {'phone': Size(390, 844), 'tablet': Size(1024, 1366)};

void main() {
  setUpAll(_loadFonts);

  for (final size in sizes.entries) {
    for (final b in Brightness.values) {
      testWidgets('sign-in ${size.key} ${b.name}', (tester) async {
        tester.view.physicalSize = size.value * 2;
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          ProviderScope(
            overrides: testOverrides(FakeApi()),
            retry: noRetry,
            child: testApp(const SignInScreen(), brightness: b),
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(find.byType(SignInScreen), matchesGoldenFile('images/sign_in_${size.key}_${b.name}.png'));
      });

      testWidgets('sold out ${size.key} ${b.name}', (tester) async {
        tester.view.physicalSize = size.value * 2;
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);
        final api = restaurantServer(role: 'staff')
          ..json('GET t/7/items?status=sold_out&sort=name&per=100&page=1', {
            'data': [
              {
                'id': 41,
                'name': {'en': 'Iced latte'},
                'category': {
                  'name': {'en': 'Coffee'},
                },
                'is_sold_out': true,
                'is_visible': true,
              },
              {
                'id': 42,
                'name': {'en': 'Shiro tegabino'},
                'category': {
                  'name': {'en': 'Mains'},
                },
                'is_sold_out': true,
                'is_visible': true,
              },
            ],
            'meta': {'page': 1, 'pages': 1},
          });
        final store = MemoryTokenStore()..values[TokenKeys.token] = 'tok';
        final container = ProviderContainer(
          overrides: testOverrides(api, store: store),
          retry: noRetry,
        );
        addTearDown(container.dispose);
        await tester.runAsync(() => container.read(sessionProvider.notifier).restore());
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: testApp(const SoldOutScreen(), brightness: b),
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(find.byType(SoldOutScreen), matchesGoldenFile('images/sold_out_${size.key}_${b.name}.png'));
      });
    }
  }
}
