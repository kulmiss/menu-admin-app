import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/cache/swr.dart';
import '../../core/providers.dart';
import '../../core/util/files.dart';
import '../../core/util/json.dart';
import '../../core/widgets/adaptive_shell.dart';
import '../../core/widgets/kit.dart';
import '../../core/widgets/paged_list.dart';
import '../restaurant/more_screen.dart' show roleLabel;
import '../restaurant/restaurant_scaffold.dart';
import '../restaurant/team_screen.dart' show stateLabel;

Color healthColor(String band) => switch (band) {
  'healthy' => const Color(0xFF16A34A),
  'at_risk' => const Color(0xFFD97706),
  _ => const Color(0xFFDC2626),
};

/// Restaurants DataTable as a list: filters, search, tags, health; on
/// tablets the detail opens beside it.
class RestaurantsScreen extends ConsumerStatefulWidget {
  const RestaurantsScreen({super.key, this.filters = const {}});
  final Map<String, String> filters;
  @override
  ConsumerState<RestaurantsScreen> createState() => _RestaurantsScreenState();
}

class _RestaurantsScreenState extends ConsumerState<RestaurantsScreen> {
  late Map<String, String> _f = {...widget.filters};
  String _q = '';
  int? _selected;

  @override
  void didUpdateWidget(covariant RestaurantsScreen old) {
    super.didUpdateWidget(old);
    if (old.filters.toString() != widget.filters.toString()) _f = {...widget.filters};
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final wide = TwoPane.isWide(context);
    final chips = <(String, String, String)>[
      ('state', 'active', l.state_active),
      ('state', 'trial', l.state_trial),
      ('state', 'grace', l.state_grace),
      ('state', 'read_only', l.state_read_only),
      ('state', 'suspended', l.status_suspended),
      ('health', 'at_risk', l.health_at_risk),
      ('health', 'inactive', l.health_inactive),
      ('follow_up', 'due', l.followUpsDue),
    ];
    final list = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SearchField(onChanged: (v) => setState(() => _q = v)),
        ),
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: [
              for (final (k, v, label) in chips)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(label: Text(label), selected: _f[k] == v, onSelected: (on) => setState(() => on ? _f[k] = v : _f.remove(k))),
                ),
              if (_f.isNotEmpty) TextButton(onPressed: () => setState(_f.clear), child: Text(l.clearFilters)),
            ],
          ),
        ),
        Expanded(
          child: PagedList(
            path: 'platform/restaurants',
            query: {..._f, if (_q.isNotEmpty) 'q': _q, 'page': '1'},
            empty: EmptyState(icon: AppIcons.searchX, title: l.noMatches),
            itemBuilder: (context, r, _) => ListTile(
              selected: r.i('id') == _selected,
              leading: CircleAvatar(
                backgroundColor: r.has('health') ? healthColor(r.o('health').s('band')).withValues(alpha: .15) : null,
                child: Text(
                  r.s('name').characters.firstOrNull?.toUpperCase() ?? '?',
                  style: TextStyle(color: r.has('health') ? healthColor(r.o('health').s('band')) : null, fontWeight: FontWeight.w700),
                ),
              ),
              title: Text(r.s('name')),
              subtitle: Text(
                [
                  r.o('plan').s('name', '—'),
                  stateLabel(context, r.s('state')),
                  if (r.sn('paid_until') != null) formatDate(context, r.s('paid_until')),
                  for (final t in r.list('tags')) '#${t.s('name')}',
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: r.has('health')
                  ? Text(
                      '${r.o('health').i('score')}',
                      style: TextStyle(color: healthColor(r.o('health').s('band')), fontWeight: FontWeight.w700),
                    )
                  : null,
              onTap: () => wide ? setState(() => _selected = r.i('id')) : context.push('/p/restaurants/${r.i('id')}'),
            ),
          ),
        ),
      ],
    );
    return RestaurantScaffold(
      title: l.restaurants,
      actions: [
        IconButton(
          tooltip: l.exportCsv,
          icon: const Icon(AppIcons.download),
          onPressed: () => downloadAndOpen(
            context,
            ref,
            'platform/restaurants',
            'restaurants.csv',
            share: true,
            query: {..._f, if (_q.isNotEmpty) 'q': _q, 'format': 'csv'},
          ),
        ),
      ],
      body: TwoPane(
        listWidth: 400,
        list: list,
        detail: _selected == null ? null : RestaurantDetail(key: ValueKey(_selected), id: _selected!),
        emptyDetail: EmptyState(icon: AppIcons.store, title: l.restaurants),
      ),
    );
  }
}

class RestaurantDetailScreen extends StatelessWidget {
  const RestaurantDetailScreen({super.key, required this.id, this.initialTab = 0});
  final int id;
  final int initialTab;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      top: false,
      child: RestaurantDetail(id: id, initialTab: initialTab, standalone: true),
    ),
  );
}

/// Plan, trial, payments – invoices, features, notes/tags/follow-up, team,
/// suspend/restore/delete and "log in as".
class RestaurantDetail extends ConsumerStatefulWidget {
  const RestaurantDetail({super.key, required this.id, this.initialTab = 0, this.standalone = false});
  final int id;
  final int initialTab;
  final bool standalone;
  @override
  ConsumerState<RestaurantDetail> createState() => _RestaurantDetailState();
}

class _RestaurantDetailState extends ConsumerState<RestaurantDetail> with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 5, vsync: this, initialIndex: widget.initialTab);
  String get _path => 'platform/restaurants/${widget.id}';

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _logInAs(J r) async {
    final l = context.l;
    if (!await confirm(context, title: l.logInAs, body: l.logInAsBody, action: l.logInAs) || !mounted) return;
    final res = await runAction(context, () => ref.read(apiProvider).post('$_path/impersonate-token'));
    if (res == null || !mounted) return;
    final d = J.data(res);
    await ref.read(sessionProvider.notifier).startImpersonation(d.s('token'), d.i('tenant_id'));
    if (mounted) {
      showSnack(context, l.logInAsStarted);
      context.go('/r/${d.i('tenant_id')}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final v = ref.watch(cachedProvider(_path));
    final r = v.value == null ? null : J.data(v.value!.data);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.standalone,
        title: Text(r?.s('name') ?? ''),
        actions: [
          if (r != null) ...[
            IconButton(tooltip: l.openMyMenu, icon: const Icon(AppIcons.externalLink), onPressed: () => openExternal(context, r.s('url'))),
            IconButton(tooltip: l.logInAs, icon: const Icon(AppIcons.logIn), onPressed: r.sn('deleted_at') != null ? null : () => _logInAs(r)),
            _DangerMenu(r: r, path: _path, onChanged: () => ref.invalidate(cachedProvider(_path))),
          ],
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: l.overview),
            Tab(text: l.payments),
            Tab(text: l.features),
            Tab(text: l.notesTags),
            Tab(text: l.team),
          ],
        ),
      ),
      floatingActionButton: r == null
          ? null
          : ListenableBuilder(
              listenable: _tabs,
              builder: (_, _) => _tabs.index == 1
                  ? FloatingActionButton.extended(
                      onPressed: () => recordPayment(context, ref, r),
                      icon: const Icon(AppIcons.plus),
                      label: Text(l.recordPayment),
                    )
                  : const SizedBox.shrink(),
            ),
      body: v.when(
        skipLoadingOnRefresh: true,
        loading: () => const Skeleton(),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(cachedProvider(_path))),
        data: (_) => TabBarView(
          controller: _tabs,
          children: [
            _OverviewTab(r: r!, path: _path),
            _PaymentsTab(r: r),
            _FeaturesTab(r: r, path: _path),
            _CrmTab(r: r, path: _path),
            ListView(
              children: [
                for (final m in r.list('members'))
                  ListTile(
                    leading: const Icon(AppIcons.user),
                    title: Text(m.s('name')),
                    subtitle: Text('${roleLabel(context, m.s('role'))} · ${m.s('email')}'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DangerMenu extends ConsumerWidget {
  const _DangerMenu({required this.r, required this.path, required this.onChanged});
  final J r;
  final String path;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final api = ref.read(apiProvider);
    final deleted = r.sn('deleted_at') != null;
    final suspended = r.s('status') == 'suspended';
    return PopupMenuButton<String>(
      onSelected: (v) async {
        switch (v) {
          case 'suspend':
            final reason = await _ask(context, l.suspendReason);
            if (reason != null && context.mounted) await runOk(context, () => api.post('$path/suspend', data: {'reason': reason}));
          case 'unsuspend':
            await runOk(context, () => api.post('$path/unsuspend'));
          case 'delete':
            if (await confirm(context, title: l.deleteRestaurant, body: l.deleteRestaurantBody, action: l.delete, danger: true) && context.mounted) {
              await runOk(context, () => api.delete(path));
            }
          case 'restore':
            await runOk(context, () => api.post('$path/restore'));
          case 'welcome':
            await runOk(context, () => api.post('$path/resend-welcome'), success: l.saved);
        }
        onChanged();
      },
      itemBuilder: (c) => [
        if (!deleted) PopupMenuItem(value: suspended ? 'unsuspend' : 'suspend', child: Text(suspended ? l.unsuspend : l.suspend)),
        if (!deleted) PopupMenuItem(value: 'welcome', child: Text(l.resendWelcome)),
        PopupMenuItem(
          value: deleted ? 'restore' : 'delete',
          child: Text(deleted ? l.restoreRestaurant : l.deleteRestaurant, style: TextStyle(color: deleted ? null : c.colors.error)),
        ),
      ],
    );
  }
}

Future<String?> _ask(BuildContext context, String label) async {
  final c = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: TextField(
        controller: c,
        autofocus: true,
        maxLines: 3,
        decoration: InputDecoration(labelText: label),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.l.cancel)),
        FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim().isEmpty ? null : c.text.trim()), child: Text(ctx.l.ok)),
      ],
    ),
  );
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab({required this.r, required this.path});
  final J r;
  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final counts = r.o('counts');
    final plans = ref.watch(cachedProvider('platform/plans')).value;
    final pl = plans == null ? <J>[] : J.dataList(plans.data);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (r.s('status') == 'suspended')
          Card(
            color: context.colors.errorContainer,
            child: ListTile(title: Text(l.status_suspended), subtitle: Text(r.s('suspended_reason'))),
          ),
        Group(
          margin: EdgeInsets.zero,
          children: [
            ListTile(title: Text(l.status), trailing: Text(stateLabel(context, r.s('state')))),
            ListTile(
              title: Text(l.plan),
              trailing: DropdownButton<int?>(
                value: pl.any((p) => p.i('id') == r.o('plan').iN('id')) ? r.o('plan').iN('id') : null,
                underline: const SizedBox.shrink(),
                items: [for (final p in pl) DropdownMenuItem(value: p.i('id'), child: Text(p.t('name')))],
                onChanged: (v) async {
                  await runOk(context, () => ref.read(apiProvider).patch(path, data: {'plan_id': v}), success: l.saved);
                  ref.invalidate(cachedProvider(path));
                },
              ),
            ),
            ListTile(
              title: Text(l.trialUntil),
              trailing: Text(formatDate(context, r.sn('trial_ends_at'))),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 730)),
                  initialDate: DateTime.tryParse(r.s('trial_ends_at')) ?? DateTime.now(),
                );
                if (d == null || !context.mounted) return;
                await runOk(context, () => ref.read(apiProvider).patch(path, data: {'trial_ends_at': DateFormat('yyyy-MM-dd').format(d)}), success: l.saved);
                ref.invalidate(cachedProvider(path));
              },
            ),
            ListTile(title: Text(l.paidUntil), trailing: Text(formatDate(context, r.sn('paid_until')))),
            ListTile(title: Text(l.owner), subtitle: Text('${r.o('owner').s('name')} · ${r.o('owner').s('email')}')),
            ListTile(title: Text(l.created), trailing: Text(formatDate(context, r.sn('created_at')))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatTile(label: l.menusCount, value: '${counts.i('menus')}'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StatTile(label: l.itemsCount, value: '${counts.i('items')}'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StatTile(label: l.views30, value: '${counts.i('views_30d')}'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Record payment – the server makes the invoice (and e-mails it if set).
Future<void> recordPayment(BuildContext context, WidgetRef ref, J r) async {
  final l = context.l;
  final amount = TextEditingController();
  final reference = TextEditingController();
  final notes = TextEditingController();
  var method = 'mobile_money';
  var months = 12;
  var paidAt = DateTime.now();
  int? planId = r.o('plan').iN('id');
  final plans = J.dataList(await ref.read(apiProvider).get('platform/plans'));
  if (!context.mounted) return;
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (c) => StatefulBuilder(
      builder: (c, set) => Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(c).bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.recordPayment, style: c.text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                initialValue: plans.any((p) => p.i('id') == planId) ? planId : null,
                decoration: InputDecoration(labelText: l.plan),
                items: [for (final p in plans) DropdownMenuItem(value: p.i('id'), child: Text(p.t('name')))],
                onChanged: (v) => set(() => planId = v),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('paymentAmount'),
                      controller: amount,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                      decoration: InputDecoration(labelText: l.amount, suffixText: r.s('currency_code')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: months,
                      decoration: InputDecoration(labelText: l.months),
                      items: [
                        for (final m in [1, 3, 6, 12, 24]) DropdownMenuItem(value: m, child: Text('$m')),
                      ],
                      onChanged: (v) => set(() => months = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: method,
                decoration: InputDecoration(labelText: l.method),
                items: [
                  DropdownMenuItem(value: 'cash', child: Text(l.method_cash)),
                  DropdownMenuItem(value: 'bank', child: Text(l.method_bank)),
                  DropdownMenuItem(value: 'mobile_money', child: Text(l.method_mobile_money)),
                  DropdownMenuItem(value: 'other', child: Text(l.method_other)),
                ],
                onChanged: (v) => set(() => method = v!),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: reference,
                decoration: InputDecoration(labelText: l.reference),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.paidOn),
                trailing: Text(DateFormat.yMMMd().format(paidAt)),
                onTap: () async {
                  final d = await showDatePicker(
                    context: c,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now(),
                    initialDate: paidAt,
                  );
                  if (d != null) set(() => paidAt = d);
                },
              ),
              TextField(
                controller: notes,
                maxLines: 2,
                decoration: InputDecoration(labelText: l.notes),
              ),
              const SizedBox(height: 12),
              FilledButton(key: const Key('savePayment'), onPressed: () => Navigator.pop(c, true), child: Text(l.save)),
            ],
          ),
        ),
      ),
    ),
  );
  if (ok != true || !context.mounted) return;
  final minor = ((double.tryParse(amount.text) ?? 0) * 100).round();
  final saved = await runOk(
    context,
    () => ref
        .read(apiProvider)
        .post(
          'platform/restaurants/${r.i('id')}/payments',
          data: {
            'amount_minor': minor,
            'method': method,
            'reference': reference.text.trim().isEmpty ? null : reference.text.trim(),
            'paid_at': DateFormat('yyyy-MM-dd').format(paidAt),
            'months': months,
            'plan_id': planId,
            'notes': notes.text.trim().isEmpty ? null : notes.text.trim(),
          },
        ),
    success: l.paymentSaved,
  );
  if (saved) ref.invalidate(cachedProvider('platform/restaurants/${r.i('id')}'));
}

class _PaymentsTab extends ConsumerWidget {
  const _PaymentsTab({required this.r});
  final J r;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final payments = r.list('payments');
    if (payments.isEmpty) return EmptyState(icon: AppIcons.banknote, title: l.payments);
    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        for (final p in payments)
          ExpansionTile(
            title: Text('${formatMoney(p.i('amount_minor'), p.s('currency'))} · ${p.s('plan')}'),
            subtitle: Text('${formatDate(context, p.s('paid_at'))} · ${p.s('period_start')} – ${p.s('period_end')}'),
            children: [
              if (p.s('reference').isNotEmpty) ListTile(dense: true, title: Text(l.reference), trailing: Text(p.s('reference'))),
              for (final i in p.list('invoices')) InvoiceTile(invoice: i, onChanged: () => ref.invalidate(cachedProvider('platform/restaurants/${r.i('id')}'))),
            ],
          ),
      ],
    );
  }
}

/// Open/share the PDF, e-mail again, void.
class InvoiceTile extends ConsumerWidget {
  const InvoiceTile({super.key, required this.invoice, this.onChanged});
  final J invoice;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final id = invoice.i('id');
    final voided = invoice.s('status') == 'void';
    return ListTile(
      leading: const Icon(AppIcons.receipt),
      title: Text('${l.invoice} ${invoice.s('number')}'),
      subtitle: voided ? Text(l.voidInvoice) : null,
      trailing: PopupMenuButton<String>(
        onSelected: (v) async {
          switch (v) {
            case 'open':
              await downloadAndOpen(context, ref, 'platform/invoices/$id/pdf', '${invoice.s('number')}.pdf');
            case 'share':
              await downloadAndOpen(context, ref, 'platform/invoices/$id/pdf', '${invoice.s('number')}.pdf', share: true);
            case 'resend':
              await runOk(context, () => ref.read(apiProvider).post('platform/invoices/$id/resend'), success: l.saved);
            case 'void':
              if (await confirm(context, title: l.voidConfirm(invoice.s('number')), action: l.voidInvoice, danger: true) && context.mounted) {
                await runOk(context, () => ref.read(apiProvider).post('platform/invoices/$id/void'));
                onChanged?.call();
              }
          }
        },
        itemBuilder: (c) => [
          PopupMenuItem(value: 'open', child: Text(l.open)),
          PopupMenuItem(value: 'share', child: Text(l.share)),
          if (!voided) PopupMenuItem(value: 'resend', child: Text(l.resendInvoice)),
          if (!voided)
            PopupMenuItem(
              value: 'void',
              child: Text(l.voidInvoice, style: TextStyle(color: c.colors.error)),
            ),
        ],
      ),
    );
  }
}

class _FeaturesTab extends ConsumerWidget {
  const _FeaturesTab({required this.r, required this.path});
  final J r;
  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final features = r.o('features');
    final overrides = r.o('overrides');
    return ListView(
      children: [
        for (final key in features.m.keys)
          ListTile(
            title: Text(key.replaceAll('_', ' ')),
            subtitle: Text(overrides.has(key) ? (overrides.b(key) ? l.featureOn : l.featureOff) : l.featureDefault),
            trailing: Switch(
              value: features.b(key),
              onChanged: (v) async {
                await runOk(
                  context,
                  () => ref
                      .read(apiProvider)
                      .put(
                        '$path/features',
                        data: {
                          'features': {key: v},
                        },
                      ),
                );
                ref.invalidate(cachedProvider(path));
              },
            ),
            onLongPress: overrides.has(key)
                ? () async {
                    await runOk(
                      context,
                      () => ref
                          .read(apiProvider)
                          .put(
                            '$path/features',
                            data: {
                              'features': {key: null},
                            },
                          ),
                    );
                    ref.invalidate(cachedProvider(path));
                  }
                : null,
          ),
      ],
    );
  }
}

class _CrmTab extends ConsumerWidget {
  const _CrmTab({required this.r, required this.path});
  final J r;
  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final api = ref.read(apiProvider);
    final notesPath = '$path/notes';
    final allTags = ref.watch(cachedProvider('platform/tags')).value;
    final tags = allTags == null ? <J>[] : J.dataList(allTags.data);
    final mine = {for (final t in r.list('tags')) t.i('id')};
    return ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        SectionHeader(l.tags),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in tags)
                FilterChip(
                  label: Text(t.s('name')),
                  selected: mine.contains(t.i('id')),
                  onSelected: (on) async {
                    final ids = on ? {...mine, t.i('id')} : ({...mine}..remove(t.i('id')));
                    await runOk(context, () => api.put('$path/tags', data: {'tag_ids': ids.toList()}));
                    ref.invalidate(cachedProvider(path));
                  },
                ),
            ],
          ),
        ),
        SectionHeader(l.followUp),
        ListTile(
          leading: const Icon(AppIcons.calendarDays),
          title: Text(r.sn('follow_up_on') == null ? l.followUpOn : formatDate(context, r.s('follow_up_on'))),
          subtitle: r.s('follow_up_reason').isEmpty ? null : Text(r.s('follow_up_reason')),
          trailing: r.sn('follow_up_on') == null
              ? null
              : IconButton(
                  tooltip: l.clearFollowUp,
                  icon: const Icon(AppIcons.x),
                  onPressed: () async {
                    await runOk(context, () => api.put('$path/follow-up', data: {'date': null}));
                    ref.invalidate(cachedProvider(path));
                  },
                ),
          onTap: () async {
            final d = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
            if (d == null || !context.mounted) return;
            final reason = await _ask(context, l.followUpReason);
            if (!context.mounted) return;
            await runOk(context, () => api.put('$path/follow-up', data: {'date': DateFormat('yyyy-MM-dd').format(d), 'reason': reason}));
            ref.invalidate(cachedProvider(path));
          },
        ),
        SectionHeader(
          l.notes,
          trailing: TextButton.icon(
            onPressed: () async {
              final body = await _ask(context, l.addNote);
              if (body == null || !context.mounted) return;
              await runOk(context, () => api.post(notesPath, data: {'body': body}));
              ref.invalidate(cachedProvider(notesPath));
            },
            icon: const Icon(AppIcons.plus),
            label: Text(l.addNote),
          ),
        ),
        Consumer(
          builder: (context, ref, _) {
            final n = ref.watch(cachedProvider(notesPath)).value;
            return Column(
              children: [
                for (final note in n == null ? <J>[] : J.dataList(n.data))
                  ListTile(
                    title: Text(note.s('body')),
                    subtitle: Text('${note.o('author').s('name', note.s('author'))} · ${formatDate(context, note.sn('created_at'), time: true)}'),
                    trailing: IconButton(
                      tooltip: l.delete,
                      icon: const Icon(AppIcons.trash2),
                      onPressed: () async {
                        await runOk(context, () => api.delete('platform/notes/${note.i('id')}'));
                        ref.invalidate(cachedProvider(notesPath));
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
