import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/cache/swr.dart';
import '../../core/util/json.dart';
import '../../core/widgets/adaptive_shell.dart';
import '../../core/widgets/kit.dart';
import 'platform_dashboard.dart';
import 'platform_more.dart';
import 'restaurants_screen.dart';

List<RouteBase> platformRoutes(Ref ref, GlobalKey<NavigatorState> rootKey) => [
  ShellRoute(
    builder: (context, state, child) {
      final l = context.l;
      final pending = ref.read(cachedProvider('platform/widgets/signups')).value;
      final count = pending == null ? 0 : J.dataList(pending.data).where((r) => r.s('signup_state') == 'pending').length;
      return ModeShell(
        location: state.uri.path,
        items: [
          NavItem(l.navDashboard, AppIcons.layoutDashboard, AppIcons.layoutDashboard, '/p'),
          NavItem(l.navRestaurants, AppIcons.store, AppIcons.store, '/p/restaurants'),
          NavItem(l.navApprovals, AppIcons.userCheck, AppIcons.userCheck, '/p/approvals', badge: count > 0 ? '$count' : null),
          NavItem(l.navSearch, AppIcons.search, AppIcons.search, '/p/search'),
          NavItem(l.navMore, AppIcons.ellipsis, AppIcons.ellipsis, '/p/more'),
        ],
        child: child,
      );
    },
    routes: [
      GoRoute(path: '/p', builder: (_, _) => const PlatformDashboard()),
      GoRoute(
        path: '/p/restaurants',
        builder: (_, s) => RestaurantsScreen(filters: s.uri.queryParameters),
      ),
      GoRoute(path: '/p/approvals', builder: (_, _) => const ApprovalsScreen()),
      GoRoute(path: '/p/search', builder: (_, _) => const SearchScreen()),
      GoRoute(path: '/p/more', builder: (_, _) => const PlatformMoreScreen()),
    ],
  ),
  GoRoute(path: '/p/dashboard', redirect: (_, _) => '/p'),
  GoRoute(
    path: '/p/restaurants/:id',
    parentNavigatorKey: rootKey,
    builder: (_, s) => RestaurantDetailScreen(id: int.parse(s.pathParameters['id']!)),
  ),
  GoRoute(
    path: '/p/restaurants/:id/payments',
    parentNavigatorKey: rootKey,
    builder: (_, s) => RestaurantDetailScreen(id: int.parse(s.pathParameters['id']!), initialTab: 1),
  ),
  for (final (path, builder) in <(String, Widget Function(GoRouterState))>[
    ('plans', (_) => const PlansScreen()),
    ('payments', (_) => const PaymentsScreen()),
    ('invoices', (_) => const InvoicesScreen()),
    ('messages', (_) => const MessagesScreen()),
    ('messages/new', (_) => const ComposeMessageScreen()),
    ('backups', (_) => const BackupsScreen()),
    ('announcements', (_) => const AnnouncementsScreen()),
    ('settings', (_) => const PlatformSettingsScreen()),
    ('activity', (_) => const PlatformActivityScreen()),
  ])
    GoRoute(path: '/p/$path', parentNavigatorKey: rootKey, builder: (_, s) => builder(s)),
];
