// Play Store screenshots from the real screens with demo data.
// `flutter test --run-skipped -t store --update-goldens test/store` (Linux).
@Tags(['store'])
library;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menu_admin/app/app.dart';
import 'package:menu_admin/app/router.dart';
import 'package:menu_admin/core/auth/token_store.dart';
import 'package:menu_admin/core/providers.dart';

import '../helpers/fake_api.dart';
import '../widgets/flows.dart';
import '../helpers/fonts.dart';

Map<String, dynamic> item(int id, String name, String cat, int price, {bool sold = false}) => {
  'id': id,
  'category_id': 5,
  'name': {'en': name},
  'price_minor': price,
  'variants': [],
  'is_sold_out': sold,
  'is_visible': true,
  'category': {
    'name': {'en': cat},
  },
  'menu': {
    'name': {'en': 'All day'},
  },
};

FakeApi demoRestaurant() {
  final coffee = [
    item(41, 'Macchiato', 'Coffee', 6000),
    item(42, 'Spris', 'Coffee', 9000),
    item(43, 'Iced latte', 'Coffee', 8500, sold: true),
    item(44, 'Buna', 'Coffee', 4000),
  ];
  final breakfast = [
    item(51, 'Firfir', 'Breakfast', 18000),
    item(52, 'Chechebsa', 'Breakfast', 16000),
    item(53, 'Ful medames', 'Breakfast', 15000),
    item(54, 'Shiro tegabino', 'Breakfast', 17000, sold: true),
  ];
  return restaurantServer(features: {'insights': true, 'promotions': true, 'price_periods': true, 'branches': true, 'pdf_menu': true, 'order_list': true})
    ..json('GET t/7/widgets/orders', {
      'data': {
        'enabled': true,
        'currency': 'ETB',
        'periods': {
          for (final (d, shown) in [('7', 64), ('30', 241)])
            d: {
              'lists_shown': shown,
              'average_minor': 48500,
              'top': [
                {
                  'id': 41,
                  'name': {'en': 'Spris'},
                  'added': shown ~/ 2,
                },
                {
                  'id': 51,
                  'name': {'en': 'Firfir'},
                  'added': shown ~/ 3,
                },
                {
                  'id': 52,
                  'name': {'en': 'Chechebsa'},
                  'added': shown ~/ 4,
                },
              ],
            },
        },
      },
    })
    ..json('GET t/7/dashboard', {
      'data': {
        'today': {'views': 214, 'scans': 107},
        'yesterday': {'views': 176, 'scans': 88},
        'sold_out': [
          {'id': 43},
          {'id': 54},
        ],
      },
    })
    ..json('GET t/7/widgets/setup', {
      'data': {
        'percent': 71,
        'complete': false,
        'hidden': false,
        'steps': [
          for (final k in ['logo', 'banner', 'dishes', 'hours', 'info']) {'key': k, 'done': true},
          {'key': 'photos', 'done': false},
          {'key': 'qr', 'done': false},
        ],
      },
    })
    ..json('GET t/7/widgets/trend', {
      'data': {
        'days': [
          for (final v in [120, 140, 132, 168, 190, 176, 214]) {'views': v, 'scans': v ~/ 2},
        ],
        'yesterday': {'views': 176, 'scans': 88},
      },
    })
    ..json('GET t/7/widgets/plan', {
      'data': {
        'plan': {'en': 'Plus'},
        'trial': false,
        'days_left': 89,
        'usage': [
          {'key': 'items', 'used': 58, 'limit': null},
          {'key': 'photos', 'used': 212, 'limit': 500},
          {'key': 'branches', 'used': 1, 'limit': 1},
        ],
        'next': {
          'name': {'en': 'Pro'},
          'adds': ['3 branches', 'Happy hour'],
        },
      },
    })
    ..json('GET t/7/menus/2/tree', {
      'data': {
        'categories': [
          {
            'id': 5,
            'name': {'en': 'Coffee'},
            'is_visible': true,
            'items': coffee,
          },
          {
            'id': 6,
            'name': {'en': 'Breakfast'},
            'is_visible': true,
            'items': breakfast,
          },
        ],
      },
    })
    ..json('GET t/7/items?status=sold_out&sort=name&per=100&page=1', {
      'data': [coffee[2], breakfast[3]],
      'meta': {'page': 1, 'pages': 1},
    })
    ..json('GET t/7/items/42', {
      'data': {
        ...dish(),
        'name': {'en': 'Spris'},
        'description': {'en': 'Layered juice of avocado, mango and papaya.'},
        'price_minor': null,
        'variants': [
          {
            'id': 1,
            'name': {'en': 'Small'},
            'price_minor': 9000,
          },
          {
            'id': 2,
            'name': {'en': 'Large'},
            'price_minor': 12000,
          },
        ],
        'tag_ids': [1],
        'allergens': ['milk'],
      },
    })
    ..json('GET t/7/tags', {
      'data': [
        {'id': 1, 'key': 'vegetarian'},
        {'id': 2, 'key': 'popular'},
        {'id': 3, 'key': 'spicy'},
      ],
    });
}

FakeApi demoPlatform() => FakeApi()
  ..json('GET me', meJson(superAdmin: true))
  ..json('GET platform/insights/overview?days=30', {
    'data': {
      'currency': 'ETB',
      'kpis': {
        'restaurants': {'value': 128, 'previous': 119},
        'paying': {'value': 74, 'previous': 69},
        'new_restaurants': {'value': 11, 'previous': 8},
        'active': {'value': 96, 'previous': 90},
        'mrr_minor': {'value': 7342000, 'previous': 6810000},
        'revenue_minor': {'value': 9120000, 'previous': 8030000},
        'menu_views': {'value': 48210, 'previous': 41100},
        'qr_scans': {'value': 20114, 'previous': 18900},
      },
      'series': [
        for (var i = 0; i < 30; i++) {'restaurants': 98 + i},
      ],
    },
  })
  ..json('GET platform/insights/engagement?days=30', {
    'data': {
      'bands': {'healthy': 79, 'at_risk': 31, 'inactive': 18},
    },
  })
  ..json('GET platform/widgets/expiring', {
    'data': [
      {'id': 9, 'name': 'Nine Wells Coffee', 'days_left': 19},
    ],
  })
  ..json('GET platform/widgets/signups', {
    'data': [
      {'id': 12, 'name': 'Blue Nile Café', 'created_at': '2026-11-13T09:00:00Z', 'signup_state': 'pending'},
    ],
  })
  ..json('GET platform/restaurants?per=50&page=1', {
    'data': [
      for (final (id, n, p, b, s) in [
        (9, 'Nine Wells Coffee', 'Pro', 'at_risk', 62),
        (7, 'Buna & Bread', 'Plus', 'healthy', 91),
        (3, 'Lalibela Grill', 'Free', 'inactive', 18),
        (5, 'Harar House', 'Business', 'healthy', 88),
        (6, 'Piassa Pastry', 'Plus', 'healthy', 77),
      ])
        {
          'id': id,
          'name': n,
          'state': 'active',
          'plan': {'name': p},
          'paid_until': '2026-12-03',
          'health': {'band': b, 'score': s},
          'tags': [],
        },
    ],
    'meta': {'page': 1, 'pages': 1},
  });

const phone = Size(392.7, 785.5); // 1080 × 2160 at 2.75
const tablet7 = Size(600, 960); // 1200 × 1920 at 2
const tablet10 = Size(1280, 800); // 2560 × 1600 at 2 (landscape: two panes)

Future<void> shoot(WidgetTester tester, FakeApi api, String path, String name, Size size, double dpr, {Future<void> Function()? then}) async {
  tester.view.physicalSize = size * dpr;
  tester.view.devicePixelRatio = dpr;
  addTearDown(tester.view.reset);
  final store = MemoryTokenStore()..values[TokenKeys.token] = 'tok';
  final c = ProviderContainer(
    overrides: testOverrides(api, store: store),
    retry: noRetry,
  );
  addTearDown(c.dispose);
  await tester.runAsync(() => c.read(sessionProvider.notifier).restore());
  await tester.pumpWidget(UncontrolledProviderScope(container: c, child: const MenuAdminApp()));
  await tester.pumpAndSettle();
  c.read(routerProvider).go(path);
  await tester.pumpAndSettle();
  if (then != null) await then();
  await expectLater(find.byType(MenuAdminApp), matchesGoldenFile('../../store/screenshots/$name.png'));
}

void main() {
  setUpAll(loadTestFonts);
  testWidgets('phone 1 dashboard', (t) => shoot(t, demoRestaurant(), '/r/7', 'phone_1_dashboard', phone, 2.75));
  testWidgets('phone 2 menu', (t) => shoot(t, demoRestaurant(), '/r/7/menu', 'phone_2_menu', phone, 2.75));
  testWidgets('phone 3 sold out', (t) => shoot(t, demoRestaurant(), '/r/7/sold-out', 'phone_3_sold_out', phone, 2.75));
  testWidgets('phone 4 dish', (t) => shoot(t, demoRestaurant(), '/r/7/dishes/42', 'phone_4_dish', phone, 2.75));
  testWidgets('phone 5 platform', (t) => shoot(t, demoPlatform(), '/p', 'phone_5_platform', phone, 2.75));
  testWidgets('tablet7 menu', (t) => shoot(t, demoRestaurant(), '/r/7/menu', 'tablet7_1_menu', tablet7, 2));
  testWidgets('tablet7 platform', (t) => shoot(t, demoPlatform(), '/p', 'tablet7_2_platform', tablet7, 2));
  testWidgets(
    'tablet10 menu',
    (t) => shoot(
      t,
      demoRestaurant(),
      '/r/7/menu',
      'tablet10_1_menu',
      tablet10,
      2,
      then: () async {
        await t.tap(find.text('Spris'));
        await t.pumpAndSettle();
      },
    ),
  );
  testWidgets('tablet10 restaurants', (t) => shoot(t, demoPlatform(), '/p/restaurants', 'tablet10_2_restaurants', tablet10, 2));
}
