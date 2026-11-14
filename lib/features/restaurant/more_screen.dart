import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/cache/swr.dart';
import '../../core/providers.dart';
import '../../core/util/json.dart';
import '../../core/widgets/kit.dart';
import '../../core/widgets/paged_list.dart';
import 'dashboard_screen.dart';
import 'restaurant_scaffold.dart';

/// Everything that doesn't fit the bottom bar, with the web's "Upgrade" badges.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sessionProvider);
    final t = ref.watch(tenantProvider)!;
    final can = ref.watch(canProvider);
    final l = context.l;
    final unread = ref.watch(cachedProvider('mobile/notifications')).value;
    final unreadCount = unread == null ? 0 : J.of(unread.data).o('meta').i('unread');

    ListTile item(IconData icon, String title, String path, {String? feature, bool show = true}) => ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: feature != null && !can.feature(feature) ? const UpgradeBadge() : const Icon(Icons.chevron_right),
      onTap: () => context.push('/r/${t.id}/$path'),
    );

    return RestaurantScaffold(
      title: l.navMore,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          if ((s.me?.tenants.length ?? 0) > 1 || (s.me?.isSuperAdmin ?? false) && !s.impersonating)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: OutlinedButton.icon(
                onPressed: () => showRestaurantSwitcher(context, ref),
                icon: const Icon(Icons.swap_horiz),
                label: Text('${t.name} · ${l.switchRestaurant}'),
              ),
            ),
          SectionHeader(l.restaurantSection),
          Group(
            children: [
              ListTile(leading: const Icon(Icons.qr_code_2), title: Text(l.openMyMenu), onTap: () => showMyMenuSheet(context, ref)),
              item(Icons.table_rows_outlined, l.allDishes, 'all-dishes'),
              if (can.manageRestaurant) ...[
                item(Icons.storefront_outlined, l.branches, 'branches'),
                item(Icons.qr_code, l.qrCodes, 'qr'),
                if (can.printMaterials) item(Icons.print_outlined, l.printMaterials, 'print'),
                item(Icons.palette_outlined, l.appearance, 'appearance'),
                item(Icons.schedule, l.infoHours, 'info'),
                item(Icons.campaign_outlined, l.promotions, 'promotions', feature: 'promotions'),
                item(Icons.local_bar_outlined, l.happyHour, 'happy-hour', feature: 'price_periods'),
              ],
              if (can.viewTeam) item(Icons.group_outlined, l.team, 'team'),
              if (can.viewActivity) item(Icons.history, l.activity, 'activity'),
              if (can.viewBilling) item(Icons.receipt_long_outlined, l.billing, 'billing'),
            ],
          ),
          SectionHeader(l.account),
          Group(
            children: [
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: Text(l.notifications),
                trailing: unreadCount > 0 ? Badge(label: Text('$unreadCount')) : const Icon(Icons.chevron_right),
                onTap: () => context.push('/inbox'),
              ),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(l.profile),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/account'),
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: Text(l.settings),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/account/app'),
              ),
            ],
          ),
          if ((s.me?.isSuperAdmin ?? false) && !s.impersonating) ...[
            SectionHeader(l.platform),
            Group(
              children: [
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings_outlined),
                  title: Text(l.openPlatform),
                  onTap: () async {
                    await ref.read(sessionProvider.notifier).selectTenant(null);
                    if (context.mounted) context.go('/p');
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Restaurant switcher for users in several restaurants.
Future<void> showRestaurantSwitcher(BuildContext context, WidgetRef ref) {
  final s = ref.read(sessionProvider);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (c) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final t in s.me!.tenants)
            ListTile(
              leading: CircleAvatar(child: Text(t.name.isEmpty ? '?' : t.name.characters.first.toUpperCase())),
              title: Text(t.name),
              subtitle: Text(roleLabel(c, t.role.name)),
              selected: t.id == s.tenantId,
              onTap: () {
                Navigator.pop(c);
                ref.read(sessionProvider.notifier).selectTenant(t.id);
                context.go('/r/${t.id}');
              },
            ),
          if (s.me!.isSuperAdmin && !s.impersonating)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: Text(c.l.platform),
              onTap: () {
                Navigator.pop(c);
                ref.read(sessionProvider.notifier).selectTenant(null);
                context.go('/p');
              },
            ),
        ],
      ),
    ),
  );
}

String roleLabel(BuildContext c, String role) => switch (role) {
  'owner' => c.l.role_owner,
  'manager' => c.l.role_manager,
  _ => c.l.role_staff,
};

/// The restaurant's change log (owners and managers).
class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tenantProvider)!;
    return Scaffold(
      appBar: AppBar(title: Text(context.l.activity)),
      body: PagedList(
        path: tenantPath(t.id, 'activity'),
        cursor: true,
        itemBuilder: (context, r, _) => ListTile(
          title: Text(activityLabel(r.s('action'))),
          subtitle: Text([r.o('actor').s('name'), formatDate(context, r.sn('created_at'), time: true)].where((x) => x.isNotEmpty).join(' · ')),
        ),
      ),
    );
  }
}

/// One platform announcement.
class NewsScreen extends ConsumerWidget {
  const NewsScreen({super.key, required this.id});
  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tenantProvider)!;
    return Scaffold(
      appBar: AppBar(title: Text(context.l.news)),
      body: CachedView(
        path: tenantPath(t.id, 'announcements'),
        builder: (context, data, _) {
          final a = J.dataList(data).where((x) => x.i('id') == id).firstOrNull;
          if (a == null) return ListView(children: [EmptyState(title: context.l.errorNotFound)]);
          ref.read(apiProvider).post(tenantPath(t.id, 'announcements/$id/read')).ignore();
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(a.t('title'), style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(formatDate(context, a.sn('starts_at')), style: TextStyle(color: context.colors.onSurfaceVariant)),
              const SizedBox(height: 16),
              SelectableText(a.t('body'), style: const TextStyle(fontSize: 16, height: 1.5)),
            ],
          );
        },
      ),
    );
  }
}

/// "item.updated" → "Item updated".
String activityLabel(String action) {
  final s = action.replaceAll(RegExp(r'[._]'), ' ').trim();
  return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
