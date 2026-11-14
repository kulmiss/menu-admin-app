import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/cache/swr.dart';
import '../../core/util/json.dart';
import '../../core/widgets/kit.dart';
import '../restaurant/restaurant_scaffold.dart';

/// Super Admin dashboard: reads the pre-computed aggregates (backend #186).
/// Every number opens the matching filtered list.
class PlatformDashboard extends ConsumerStatefulWidget {
  const PlatformDashboard({super.key});
  @override
  ConsumerState<PlatformDashboard> createState() => _PlatformDashboardState();
}

class _PlatformDashboardState extends ConsumerState<PlatformDashboard> {
  int _days = 30;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final q = '?days=$_days';
    final paths = [
      'platform/insights/overview$q',
      'platform/insights/engagement$q',
      'platform/insights/top$q',
      'platform/widgets/expiring',
      'platform/widgets/signups',
      'platform/widgets/health',
      'platform/widgets/follow-ups',
      'platform/widgets/inactive',
    ];
    return RestaurantScaffold(
      title: l.navDashboard,
      actions: [
        PopupMenuButton<int>(
          initialValue: _days,
          icon: const Icon(AppIcons.calendarRange),
          tooltip: l.last7days,
          onSelected: (v) => setState(() => _days = v),
          itemBuilder: (c) => [
            PopupMenuItem(value: 7, child: Text(l.days7)),
            PopupMenuItem(value: 30, child: Text(l.days30)),
            PopupMenuItem(value: 90, child: Text(l.days90)),
            PopupMenuItem(value: 365, child: Text(l.days365)),
          ],
        ),
        IconButton(tooltip: l.inbox, icon: const Icon(AppIcons.bell), onPressed: () => context.push('/inbox')),
      ],
      body: RefreshIndicator(
        onRefresh: () => ref.refreshPaths(paths),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _Overview(path: paths[0]),
            _Engagement(path: paths[1]),
            SectionHeader(l.needsAttention),
            _Attention(),
            _Top(path: paths[2]),
          ],
        ),
      ),
    );
  }
}

class _Overview extends ConsumerWidget {
  const _Overview({required this.path});
  final String path;

  String _delta(int v, int p) {
    if (p == 0) return v == 0 ? '0' : '+$v';
    final pct = ((v - p) * 100 / p).round();
    return '${pct >= 0 ? '+' : ''}$pct %';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = ref.watch(cachedProvider(path));
    final l = context.l;
    return v.when(
      skipLoadingOnRefresh: true,
      loading: () => const SizedBox(height: 260, child: Skeleton(lines: 3)),
      error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(cachedProvider(path))),
      data: (c) {
        final d = J.data(c.data);
        final k = d.o('kpis');
        final cur = d.s('currency');
        final tiles = <(String, J, String?, bool)>[
          (l.kpiRestaurants, k.o('restaurants'), '/p/restaurants', false),
          (l.kpiPaying, k.o('paying'), '/p/restaurants?state=active', false),
          (l.kpiNew, k.o('new_restaurants'), '/p/restaurants?sort=-created_at', false),
          (l.kpiActive, k.o('active'), '/p/restaurants?health=healthy', false),
          (l.kpiMrr, k.o('mrr_minor'), '/p/payments', true),
          (l.kpiRevenue, k.o('revenue_minor'), '/p/payments', true),
          (l.kpiViews, k.o('menu_views'), null, false),
          (l.kpiScans, k.o('qr_scans'), null, false),
        ];
        final series = d.list('series');
        return Column(
          children: [
            GridView.count(
              crossAxisCount: MediaQuery.sizeOf(context).width >= 840 ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.6,
              children: [
                for (final (label, kpi, link, money) in tiles)
                  StatTile(
                    label: label,
                    value: money ? formatMoney(kpi.i('value'), cur) : '${kpi.i('value')}',
                    hint: l.vsPrevious(_delta(kpi.i('value'), kpi.i('previous'))),
                    hintColor: kpi.i('value') >= kpi.i('previous') ? const Color(0xFF15803D) : context.colors.error,
                    onTap: link == null ? null : () => context.go(link),
                  ),
              ],
            ),
            if (series.isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 8),
                        child: Text(l.growth, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      SizedBox(
                        height: 150,
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            titlesData: const FlTitlesData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: [for (var i = 0; i < series.length; i++) FlSpot(i.toDouble(), series[i].i('restaurants').toDouble())],
                                color: context.colors.primary,
                                barWidth: 2.5,
                                isCurved: true,
                                preventCurveOverShooting: true,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(show: true, color: context.colors.primary.withValues(alpha: .1)),
                              ),
                            ],
                          ),
                          duration: context.reduceMotion ? Duration.zero : const Duration(milliseconds: 250),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Engagement extends ConsumerWidget {
  const _Engagement({required this.path});
  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(cachedProvider(path)).value;
    if (c == null) return const SizedBox.shrink();
    final d = J.data(c.data);
    final b = d.o('bands');
    final total = (b.i('healthy') + b.i('at_risk') + b.i('inactive')).clamp(1, 1 << 30);
    final l = context.l;
    final bands = [
      ('healthy', l.health_healthy, const Color(0xFF16A34A)),
      ('at_risk', l.health_at_risk, const Color(0xFFD97706)),
      ('inactive', l.health_inactive, const Color(0xFFDC2626)),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.healthGroups, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Row(
                  children: [
                    for (final (k, _, color) in bands)
                      if (b.i(k) > 0)
                        Expanded(
                          flex: (b.i(k) * 1000 / total).round().clamp(1, 1000),
                          child: Container(height: 14, color: color),
                        ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: [
                  for (final (k, label, color) in bands)
                    ActionChip(
                      avatar: CircleAvatar(backgroundColor: color, radius: 5),
                      label: Text('$label ${b.i(k)}'),
                      onPressed: () => context.go('/p/restaurants?health=$k'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Attention extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    Widget list(String path, String title, IconData icon, List<(String, String, int)> Function(dynamic) rows, {String? more}) {
      final v = ref.watch(cachedProvider(path)).value;
      if (v == null) return const SizedBox.shrink();
      final r = rows(v.data);
      if (r.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: Icon(icon),
                title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: more == null ? null : TextButton(onPressed: () => context.go(more), child: Text(l.more)),
              ),
              for (final (name, sub, id) in r.take(4))
                ListTile(
                  dense: true,
                  title: Text(name),
                  subtitle: Text(sub),
                  trailing: const Icon(AppIcons.chevronRight),
                  onTap: () => context.push('/p/restaurants/$id'),
                ),
            ],
          ),
        ),
      );
    }

    final health = ref.watch(cachedProvider('platform/widgets/health')).value;
    final warnings = health == null
        ? <String>[]
        : [for (final w in (J.data(health.data)['warnings'] as List? ?? const [])) w is Map ? '${w['message'] ?? w['key']}' : '$w'];
    return Column(
      children: [
        if (warnings.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              color: context.colors.errorContainer,
              child: ListTile(leading: const Icon(AppIcons.activity), title: Text(l.systemHealth), subtitle: Text(warnings.join('\n'))),
            ),
          ),
        list(
          'platform/widgets/follow-ups',
          l.followUpsDue,
          AppIcons.calendarDays,
          (d) => [for (final r in J.dataList(d)) (r.s('name'), '${r.s('date')} · ${r.s('reason')}', r.i('id'))],
          more: '/p/restaurants?follow_up=due',
        ),
        list(
          'platform/widgets/signups',
          l.newSignups,
          AppIcons.store,
          (d) => [for (final r in J.dataList(d)) (r.s('name'), formatDate(context, r.sn('created_at')), r.i('id'))],
          more: '/p/approvals',
        ),
        list(
          'platform/widgets/expiring',
          l.expiringSoon,
          AppIcons.calendarX,
          (d) => [for (final r in J.dataList(d)) (r.s('name'), l.planEndsIn(r.i('days_left')), r.i('id'))],
          more: '/p/restaurants?state=active&sort=paid_until',
        ),
        list(
          'platform/widgets/inactive',
          l.inactiveRestaurants,
          AppIcons.moon,
          (d) => [for (final r in J.dataList(d)) (r.s('name'), r.s('last_activity'), r.i('id'))],
          more: '/p/restaurants?health=inactive',
        ),
      ],
    );
  }
}

class _Top extends ConsumerWidget {
  const _Top({required this.path});
  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(cachedProvider(path)).value;
    if (c == null) return const SizedBox.shrink();
    final d = J.data(c.data);
    final rows = d.list('views');
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(context.l.topRestaurants),
        Group(
          margin: EdgeInsets.zero,
          children: [
            for (final r in rows.take(5))
              ListTile(title: Text(r.s('name')), trailing: Text('${r.i('total')}'), onTap: () => context.push('/p/restaurants/${r.i('id')}')),
          ],
        ),
      ],
    );
  }
}
