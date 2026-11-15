import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cache/swr.dart';
import '../../core/providers.dart';
import '../../core/util/files.dart';
import '../../core/util/json.dart';
import '../../core/widgets/kit.dart';
import 'restaurant_scaffold.dart';

/// Views and scans with charts, top dishes, scans per code, CSV/PDF export
/// and the monthly report switch.
class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});
  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  int _days = 30;
  int? _branch;

  Map<String, String> get _q => {'days': '$_days', if (_branch != null) 'branch_id': '$_branch'};

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(tenantProvider)!;
    final can = ref.watch(canProvider);
    final l = context.l;
    if (!can.feature('insights')) {
      return RestaurantScaffold(
        title: l.insights,
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [UpgradeCard(upgrade: t.upgrade)],
        ),
      );
    }
    final path = tenantPath(t.id, 'insights?days=$_days${_branch == null ? '' : '&branch_id=$_branch'}');
    final branches = ref.watch(cachedProvider(tenantPath(t.id, 'branches'))).value;
    final bl = branches == null ? <J>[] : J.dataList(branches.data);
    return RestaurantScaffold(
      title: l.insights,
      actions: [
        PopupMenuButton<String>(
          tooltip: l.export,
          icon: const Icon(AppIcons.share),
          onSelected: (v) {
            final base = tenantPath(t.id, v == 'pdf' ? 'insights/report.pdf' : 'insights/export.csv');
            downloadAndOpen(
              context,
              ref,
              base,
              '${t.slug}-insights-$v.${v == 'pdf' ? 'pdf' : 'csv'}',
              share: v != 'pdf',
              query: {..._q, if (v != 'pdf') 'table': v},
            );
          },
          itemBuilder: (c) => [
            PopupMenuItem(value: 'daily', child: Text(l.exportViews)),
            PopupMenuItem(value: 'qr', child: Text(l.exportQr)),
            PopupMenuItem(value: 'dishes', child: Text(l.exportDishes)),
            PopupMenuItem(value: 'pdf', child: Text(l.exportPdf)),
          ],
        ),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<int>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(value: 7, label: Text(l.days7)),
                      ButtonSegment(value: 30, label: Text(l.days30)),
                      ButtonSegment(value: 90, label: Text(l.days90)),
                    ],
                    selected: {_days},
                    onSelectionChanged: (s) => setState(() => _days = s.first),
                  ),
                ),
                if (bl.length > 1) ...[
                  const SizedBox(width: 8),
                  DropdownButton<int?>(
                    value: _branch,
                    items: [
                      DropdownMenuItem(value: null, child: Text(l.allBranches)),
                      for (final b in bl) DropdownMenuItem(value: b.i('id'), child: Text(b.s('name'))),
                    ],
                    onChanged: (v) => setState(() => _branch = v),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: CachedView(
              path: path,
              builder: (context, data, _) {
                final d = J.data(data);
                final days = d.list('days');
                final totals = d.o('totals');
                final maxY = days.fold<int>(1, (a, x) => [a, x.i('views'), x.i('scans')].reduce((p, q) => p > q ? p : q)).toDouble();
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: StatTile(label: l.menuViews, value: '${totals.i('views')}'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: StatTile(label: l.qrScans, value: '${totals.i('scans')}'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: StatTile(label: l.dishViews, value: '${totals.i('item_views')}'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                        child: SizedBox(
                          height: 180,
                          child: Semantics(
                            label: '${l.menuViews} ${totals.i('views')}, ${l.qrScans} ${totals.i('scans')}',
                            child: LineChart(
                              LineChartData(
                                minY: 0,
                                maxY: maxY * 1.15,
                                gridData: FlGridData(
                                  drawVerticalLine: false,
                                  getDrawingHorizontalLine: (_) => FlLine(color: context.colors.outlineVariant, strokeWidth: 1),
                                ),
                                borderData: FlBorderData(show: false),
                                titlesData: FlTitlesData(
                                  topTitles: const AxisTitles(),
                                  rightTitles: const AxisTitles(),
                                  bottomTitles: const AxisTitles(),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 36,
                                      getTitlesWidget: (v, m) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 11)),
                                    ),
                                  ),
                                ),
                                lineBarsData: [
                                  for (final (key, color) in [('views', context.colors.primary), ('scans', context.colors.onSurfaceVariant)])
                                    LineChartBarData(
                                      spots: [for (var i = 0; i < days.length; i++) FlSpot(i.toDouble(), days[i].i(key).toDouble())],
                                      isCurved: true,
                                      preventCurveOverShooting: true,
                                      color: color,
                                      barWidth: 2.5,
                                      dotData: const FlDotData(show: false),
                                    ),
                                ],
                              ),
                              duration: context.reduceMotion ? Duration.zero : const Duration(milliseconds: 250),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _Legend(color: context.colors.primary, label: l.menuViews),
                        const SizedBox(width: 16),
                        _Legend(color: context.colors.onSurfaceVariant, label: l.qrScans),
                      ],
                    ),
                    SectionHeader(l.topDishes),
                    Group(
                      margin: EdgeInsets.zero,
                      children: [
                        for (final x in d.list('top_items').take(10)) ListTile(dense: true, title: Text(x.s('name', '—')), trailing: Text('${x.i('count')}')),
                        if (d.list('top_items').isEmpty) ListTile(title: Text(context.l.emptyTitle)),
                      ],
                    ),
                    SectionHeader(l.scansPerCode),
                    Group(
                      margin: EdgeInsets.zero,
                      children: [
                        for (final x in d.list('scans'))
                          ListTile(dense: true, title: Text(x.b('deleted') ? l.deletedCode : x.s('label', x.s('code'))), trailing: Text('${x.i('count')}')),
                        if (d.list('scans').isEmpty) ListTile(title: Text(context.l.emptyTitle)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _MonthlySwitch(tenantId: t.id),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(width: 12, height: 3, color: color),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 12)),
    ],
  );
}

class _MonthlySwitch extends ConsumerStatefulWidget {
  const _MonthlySwitch({required this.tenantId});
  final int tenantId;
  @override
  ConsumerState<_MonthlySwitch> createState() => _MonthlySwitchState();
}

class _MonthlySwitchState extends ConsumerState<_MonthlySwitch> {
  bool? _value;

  @override
  Widget build(BuildContext context) {
    final path = tenantPath(widget.tenantId, 'insights/settings');
    final v = ref.watch(cachedProvider(path)).value;
    final server = v == null ? false : J.data(v.data).b('monthly_email');
    return Card(
      child: SwitchListTile(
        title: Text(context.l.monthlyReport),
        subtitle: Text(context.l.monthlyReportHint),
        value: _value ?? server,
        onChanged: (x) async {
          setState(() => _value = x);
          final ok = await runOk(context, () => ref.read(apiProvider).put(path, data: {'monthly_email': x}));
          if (!ok && mounted) setState(() => _value = !x);
        },
      ),
    );
  }
}
