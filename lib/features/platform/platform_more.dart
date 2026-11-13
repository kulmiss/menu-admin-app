import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/cache/swr.dart';
import '../../core/providers.dart';
import '../../core/util/json.dart';
import '../../core/util/photos.dart';
import '../../core/widgets/kit.dart';
import '../../core/widgets/net_image.dart';
import '../../core/widgets/paged_list.dart';
import '../restaurant/dish_editor_screen.dart' show minorToText, textToMinor;
import '../restaurant/more_screen.dart' show activityLabel, showRestaurantSwitcher;
import '../restaurant/restaurant_scaffold.dart';
import 'restaurants_screen.dart' show InvoiceTile;

class PlatformMoreScreen extends ConsumerWidget {
  const PlatformMoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final s = ref.watch(sessionProvider);
    ListTile item(IconData i, String t, String p) =>
        ListTile(leading: Icon(i), title: Text(t), trailing: const Icon(Icons.chevron_right), onTap: () => context.push(p));
    return RestaurantScaffold(
      title: l.navMore,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          SectionHeader(l.platform),
          Group(
            children: [
              item(Icons.workspace_premium_outlined, l.plans, '/p/plans'),
              item(Icons.payments_outlined, l.paymentsTitle, '/p/payments'),
              item(Icons.receipt_long_outlined, l.invoicesTitle, '/p/invoices'),
              item(Icons.mail_outline, l.messages, '/p/messages'),
              item(Icons.campaign_outlined, l.announcements, '/p/announcements'),
              item(Icons.backup_outlined, l.backups, '/p/backups'),
              item(Icons.history, l.platformActivity, '/p/activity'),
              item(Icons.settings_outlined, l.platformSettings, '/p/settings'),
            ],
          ),
          if ((s.me?.tenants.length ?? 0) > 0) ...[
            SectionHeader(l.restaurantSection),
            Group(
              children: [
                ListTile(leading: const Icon(Icons.storefront_outlined), title: Text(l.switchRestaurant), onTap: () => showRestaurantSwitcher(context, ref)),
              ],
            ),
          ],
          SectionHeader(l.account),
          Group(
            children: [
              item(Icons.notifications_outlined, l.notifications, '/inbox'),
              item(Icons.person_outline, l.profile, '/account'),
              item(Icons.settings_outlined, l.appSettings, '/account/app'),
            ],
          ),
        ],
      ),
    );
  }
}

class ApprovalsScreen extends ConsumerWidget {
  const ApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final key = GlobalKey<PagedListState>();
    return RestaurantScaffold(
      title: l.approvals,
      body: PagedList(
        key: key,
        path: 'platform/restaurants',
        query: const {'state': 'pending'},
        empty: EmptyState(icon: Icons.how_to_reg_outlined, title: l.approvalsEmpty),
        itemBuilder: (context, r, _) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.s('name'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  Text(
                    '${r.o('owner').s('name')} · ${r.o('owner').s('email')} · ${formatDate(context, r.sn('created_at'))}',
                    style: TextStyle(color: context.colors.onSurfaceVariant),
                  ),
                  Text(r.s('signup_state'), style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton(onPressed: () => context.push('/p/restaurants/${r.i('id')}'), child: Text(l.open)),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final c = TextEditingController();
                          final reason = await showDialog<String>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(l.reject),
                              content: TextField(
                                controller: c,
                                maxLines: 3,
                                decoration: InputDecoration(labelText: l.rejectReason),
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
                                FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: Text(l.reject)),
                              ],
                            ),
                          );
                          if (reason == null || reason.length < 3 || !context.mounted) return;
                          await runOk(context, () => ref.read(apiProvider).post('platform/restaurants/${r.i('id')}/reject', data: {'reason': reason}));
                          await key.currentState?.refresh();
                        },
                        child: Text(l.reject, style: TextStyle(color: context.colors.error)),
                      ),
                      FilledButton(
                        onPressed: () async {
                          await runOk(context, () => ref.read(apiProvider).post('platform/restaurants/${r.i('id')}/approve'), success: l.saved);
                          ref.invalidate(cachedProvider('platform/widgets/signups'));
                          await key.currentState?.refresh();
                        },
                        child: Text(l.approve),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final groups = {
      'restaurants': l.group_restaurants,
      'owners': l.group_owners,
      'invoices': l.group_invoices,
      'payments': l.group_payments,
      'tags': l.group_tags,
    };
    return RestaurantScaffold(
      title: l.navSearch,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchField(autofocus: true, hint: l.globalSearch, onChanged: (v) => setState(() => _q = v)),
          ),
          Expanded(
            child: _q.length < 2
                ? EmptyState(icon: Icons.search, title: l.searchMin)
                : CachedView(
                    path: 'platform/search?q=${Uri.encodeQueryComponent(_q)}',
                    builder: (context, data, _) {
                      final d = J.data(data);
                      final any = groups.keys.any((g) => d.list(g).isNotEmpty);
                      if (!any) {
                        return ListView(
                          children: [EmptyState(icon: Icons.search_off, title: l.noMatches)],
                        );
                      }
                      return ListView(
                        children: [
                          for (final g in groups.entries)
                            if (d.list(g.key).isNotEmpty) ...[
                              SectionHeader(g.value),
                              for (final r in d.list(g.key))
                                ListTile(
                                  title: Text(r.s('title')),
                                  subtitle: r.sn('subtitle') == null ? null : Text(r.s('subtitle')),
                                  onTap: () => g.key == 'tags'
                                      ? context.go('/p/restaurants?tag=${r.i('id')}')
                                      : (r.iN('tenant_id') != null ? context.push('/p/restaurants/${r.i('tenant_id')}') : null),
                                ),
                            ],
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

class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    return Scaffold(
      appBar: AppBar(title: Text(l.plans)),
      body: CachedView(
        path: 'platform/plans',
        builder: (context, data, _) => ListView(
          children: [
            for (final p in J.dataList(data))
              ListTile(
                title: Text(p.t('name')),
                subtitle: Text(
                  '${formatMoney(p.i('price_minor'), p.s('currency'))} / ${p.s('interval')} · ${l.restaurantsOnPlan(p.i('restaurants'))}${p.b('is_public') ? '' : ' · hidden'}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PlanEditor(plan: p))),
              ),
          ],
        ),
      ),
    );
  }
}

class PlanEditor extends ConsumerStatefulWidget {
  const PlanEditor({super.key, required this.plan});
  final J plan;
  @override
  ConsumerState<PlanEditor> createState() => _PlanEditorState();
}

class _PlanEditorState extends ConsumerState<PlanEditor> {
  late final _name = TextEditingController(text: widget.plan.t('name'));
  late final _price = TextEditingController(text: minorToText(widget.plan.iN('price_minor')));
  late final _year = TextEditingController(text: minorToText(widget.plan.iN('price_year_minor')));
  late final _trial = TextEditingController(text: '${widget.plan.i('trial_days')}');
  late final Map<String, TextEditingController> _limits = {
    for (final k in ['photos', 'branches', 'menus', 'items', 'tables', 'members', 'languages'])
      k: TextEditingController(text: widget.plan.o('limits').iN(k)?.toString() ?? ''),
  };
  late final Map<String, bool> _features = {for (final e in widget.plan.o('features').m.entries) e.key: e.value == true};
  late bool _public = widget.plan.b('is_public');

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    String limitLabel(String k) => switch (k) {
      'photos' => l.limit_photos,
      'branches' => l.limit_branches,
      'menus' => l.limit_menus,
      'items' => l.limit_items,
      'tables' => l.limit_tables,
      'members' => l.limit_members,
      _ => l.limit_languages,
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plan.t('name')),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: () async {
                final ok = await runOk(
                  context,
                  () => ref
                      .read(apiProvider)
                      .patch(
                        'platform/plans/${widget.plan.i('id')}',
                        data: {
                          'name': {...?(widget.plan['name'] as Map?)?.cast<String, dynamic>(), 'en': _name.text.trim()},
                          'price_minor': textToMinor(_price.text) ?? 0,
                          'price_year_minor': textToMinor(_year.text),
                          'trial_days': int.tryParse(_trial.text) ?? 0,
                          'limits': {for (final e in _limits.entries) e.key: int.tryParse(e.value.text)},
                          'features': _features,
                          'is_public': _public,
                        },
                      ),
                  success: l.saved,
                );
                if (ok && context.mounted) {
                  ref.invalidate(cachedProvider('platform/plans'));
                  Navigator.pop(context);
                }
              },
              child: Text(l.save),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            decoration: InputDecoration(labelText: l.planName),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _price,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l.priceMonth, suffixText: widget.plan.s('currency')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _year,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l.priceYear),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _trial,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l.trialDays),
          ),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(l.publicPlan), value: _public, onChanged: (v) => setState(() => _public = v)),
          SectionHeader(l.limits),
          for (final e in _limits.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: e.value,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(labelText: limitLabel(e.key), hintText: l.unlimited),
              ),
            ),
          SectionHeader(l.features),
          for (final e in _features.entries)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(e.key.replaceAll('_', ' ')),
              value: e.value,
              onChanged: (v) => setState(() => _features[e.key] = v),
            ),
        ],
      ),
    );
  }
}

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: Text(context.l.paymentsTitle)),
    body: PagedList(
      path: 'platform/payments',
      itemBuilder: (context, p, _) => ListTile(
        title: Text('${p.o('tenant').s('name')} · ${formatMoney(p.i('amount_minor'), p.s('currency'))}'),
        subtitle: Text('${formatDate(context, p.s('paid_at'))} · ${p.s('method')} · ${p.s('plan')}${p.s('reference').isEmpty ? '' : ' · ${p.s('reference')}'}'),
        onTap: () => context.push('/p/restaurants/${p.o('tenant').i('id')}/payments'),
      ),
    ),
  );
}

class InvoicesScreen extends ConsumerWidget {
  const InvoicesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: Text(context.l.invoicesTitle)),
    body: PagedList(
      path: 'platform/invoices',
      itemBuilder: (context, i, _) => Column(
        children: [
          ListTile(
            dense: true,
            title: Text('${i.o('tenant').s('name')} · ${formatMoney(i.i('total_minor'), i.s('currency'))}'),
            subtitle: Text('${formatDate(context, i.sn('issued_at'))} · ${i.s('plan')}'),
          ),
          InvoiceTile(invoice: i),
        ],
      ),
    ),
  );
}

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    return Scaffold(
      appBar: AppBar(title: Text(l.messages)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/p/messages/new'),
        icon: const Icon(Icons.edit_outlined),
        label: Text(l.newMessage),
      ),
      body: CachedView(
        path: 'platform/campaigns',
        builder: (context, data, _) => ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            for (final c in J.dataList(data))
              ListTile(
                title: Text(c.s('subject')),
                subtitle: Text(
                  '${formatDate(context, c.sn('created_at'), time: true)} · ${l.sent} ${c.i('sent')} · ${l.failed} ${c.i('failed')} · ${l.waiting} ${c.i('pending')}',
                ),
                trailing: c.i('failed') > 0
                    ? TextButton(
                        onPressed: () async {
                          await runOk(context, () => ref.read(apiProvider).post('platform/campaigns/${c.i('id')}/retry'), success: l.campaignSent);
                          ref.invalidate(cachedProvider('platform/campaigns'));
                        },
                        child: Text(l.retryFailed),
                      )
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}

class ComposeMessageScreen extends ConsumerStatefulWidget {
  const ComposeMessageScreen({super.key});
  @override
  ConsumerState<ComposeMessageScreen> createState() => _ComposeMessageScreenState();
}

class _ComposeMessageScreenState extends ConsumerState<ComposeMessageScreen> {
  final _subject = TextEditingController();
  final _body = TextEditingController();
  final Map<String, Object?> _filters = {};
  int? _count;

  Map<String, dynamic> get _payload => {
    'subject': _subject.text,
    'body': _body.text,
    'filters': {
      for (final e in _filters.entries)
        if (e.value != null) e.key: e.value,
    },
  };

  Future<void> _recount() async {
    try {
      final r = J.data(await ref.read(apiProvider).post('platform/campaigns/count', data: {'filters': _payload['filters']}));
      if (mounted) setState(() => _count = r.i('count'));
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _recount();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final plans = ref.watch(cachedProvider('platform/plans')).value;
    final tags = ref.watch(cachedProvider('platform/tags')).value;
    final statuses = {
      'active': l.status_active,
      'trial': l.status_trial,
      'expiring': l.status_expiring,
      'expired': l.status_expired,
      'suspended': l.status_suspended,
    };
    final ready = _subject.text.trim().isNotEmpty && _body.text.trim().isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: Text(l.newMessage)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l.recipients, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              DropdownButton<int?>(
                hint: Text(l.filterPlan),
                value: _filters['plan_id'] as int?,
                items: [
                  DropdownMenuItem(value: null, child: Text(l.allPlans)),
                  for (final p in plans == null ? <J>[] : J.dataList(plans.data)) DropdownMenuItem(value: p.i('id'), child: Text(p.t('name'))),
                ],
                onChanged: (v) {
                  setState(() => _filters['plan_id'] = v);
                  _recount();
                },
              ),
              DropdownButton<String?>(
                hint: Text(l.filterStatus),
                value: _filters['status'] as String?,
                items: [
                  DropdownMenuItem(value: null, child: Text(l.all)),
                  for (final e in statuses.entries) DropdownMenuItem(value: e.key, child: Text(e.value)),
                ],
                onChanged: (v) {
                  setState(() => _filters['status'] = v);
                  _recount();
                },
              ),
              DropdownButton<int?>(
                hint: Text(l.filterTag),
                value: _filters['tag_id'] as int?,
                items: [
                  DropdownMenuItem(value: null, child: Text(l.all)),
                  for (final t in tags == null ? <J>[] : J.dataList(tags.data)) DropdownMenuItem(value: t.i('id'), child: Text(t.s('name'))),
                ],
                onChanged: (v) {
                  setState(() => _filters['tag_id'] = v);
                  _recount();
                },
              ),
            ],
          ),
          TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l.filterInactiveDays),
            onChanged: (v) {
              _filters['inactive_days'] = int.tryParse(v);
              _recount();
            },
          ),
          const SizedBox(height: 8),
          Text(
            _count == null ? '…' : l.recipientsCount(_count!),
            style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _subject,
            maxLength: 150,
            decoration: InputDecoration(labelText: l.subject),
            onChanged: (_) => setState(() {}),
          ),
          TextField(
            controller: _body,
            minLines: 6,
            maxLines: 16,
            decoration: InputDecoration(labelText: l.message, helperText: l.placeholdersHint, helperMaxLines: 2),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: ready
                      ? () => runOk(context, () => ref.read(apiProvider).post('platform/campaigns/test', data: _payload), success: l.testSent)
                      : null,
                  child: Text(l.sendTest),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: ready && (_count ?? 0) > 0
                      ? () async {
                          if (!await confirm(context, title: l.sendConfirm(_count!), action: l.sendNow) || !context.mounted) return;
                          if (await runOk(context, () => ref.read(apiProvider).post('platform/campaigns', data: _payload), success: l.campaignSent) &&
                              context.mounted) {
                            ref.invalidate(cachedProvider('platform/campaigns'));
                            context.pop();
                          }
                        }
                      : null,
                  child: Text(l.sendNow),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BackupsScreen extends ConsumerWidget {
  const BackupsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    String size(num? b) => b == null
        ? '—'
        : b > 1e9
        ? '${(b / 1e9).toStringAsFixed(1)} GB'
        : '${(b / 1e6).toStringAsFixed(1)} MB';
    return Scaffold(
      appBar: AppBar(title: Text(l.backups)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await runOk(context, () => ref.read(apiProvider).post('platform/backups'), success: l.backupQueued);
          ref.invalidate(cachedProvider('platform/backups'));
        },
        icon: const Icon(Icons.backup_outlined),
        label: Text(l.backUpNow),
      ),
      body: CachedView(
        path: 'platform/backups',
        builder: (context, data, _) {
          final d = J.data(data);
          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              if (d.sn('problem') != null)
                Card(
                  margin: const EdgeInsets.all(16),
                  color: context.colors.errorContainer,
                  child: ListTile(leading: const Icon(Icons.warning_amber), title: Text(l.backupProblem), subtitle: Text(d.s('problem'))),
                ),
              ListTile(leading: const Icon(Icons.storage_outlined), title: Text(l.diskFree(size(d['disk_free'] as num?), size(d['disk_total'] as num?)))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(l.backupDownloadsWeb, style: TextStyle(fontSize: 13, color: context.colors.onSurfaceVariant)),
              ),
              for (final b in d.list('backups'))
                ListTile(
                  leading: Icon(
                    b.s('status') == 'ok' ? Icons.check_circle_outline : (b.s('status') == 'failed' ? Icons.error_outline : Icons.hourglass_empty),
                    color: b.s('status') == 'failed' ? context.colors.error : null,
                  ),
                  title: Text(formatDate(context, b.sn('created_at'), time: true)),
                  subtitle: Text(
                    [
                      b.s('kind'),
                      b.s('status'),
                      size(b['size'] as num?),
                      if (b.s('offsite').isNotEmpty) '${l.offsite}: ${b.s('offsite')}',
                      if (b.s('error').isNotEmpty) b.s('error'),
                    ].join(' · '),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});

  Future<void> _edit(BuildContext context, WidgetRef ref, J? a) async {
    final l = context.l;
    final title = TextEditingController(text: a?.t('title'));
    final body = TextEditingController(text: a?.t('body'));
    var level = a?.s('level', 'info') ?? 'info';
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(c).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: title,
                maxLength: 120,
                decoration: InputDecoration(labelText: l.title),
              ),
              TextField(
                controller: body,
                minLines: 3,
                maxLines: 8,
                decoration: InputDecoration(labelText: l.text),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'info', label: Text(l.level_info)),
                  ButtonSegment(value: 'warning', label: Text(l.level_warning)),
                ],
                selected: {level},
                onSelectionChanged: (s) => set(() => level = s.first),
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l.save)),
            ],
          ),
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    final data = {
      'title': {'en': title.text.trim()},
      'body': {'en': body.text.trim()},
      'level': level,
    };
    await runOk(
      context,
      () => a == null
          ? ref.read(apiProvider).post('platform/announcements', data: data)
          : ref.read(apiProvider).patch('platform/announcements/${a.i('id')}', data: data),
      success: l.saved,
    );
    ref.invalidate(cachedProvider('platform/announcements'));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    return Scaffold(
      appBar: AppBar(title: Text(l.announcements)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, ref, null),
        icon: const Icon(Icons.add),
        label: Text(l.newAnnouncementTitle),
      ),
      body: CachedView(
        path: 'platform/announcements',
        builder: (context, data, _) => ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            for (final a in J.dataList(data))
              ListTile(
                leading: Icon(a.s('level') == 'warning' ? Icons.warning_amber : Icons.campaign_outlined),
                title: Text(a.t('title')),
                subtitle: Text(a.t('body'), maxLines: 2, overflow: TextOverflow.ellipsis),
                onTap: () => _edit(context, ref, a),
                trailing: IconButton(
                  tooltip: l.delete,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    if (await confirm(context, title: l.confirmDeleteTitle(a.t('title')), action: l.delete, danger: true) && context.mounted) {
                      await runOk(context, () => ref.read(apiProvider).delete('platform/announcements/${a.i('id')}'));
                      ref.invalidate(cachedProvider('platform/announcements'));
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PlatformActivityScreen extends ConsumerWidget {
  const PlatformActivityScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: Text(context.l.platformActivity)),
    body: PagedList(
      path: 'platform/activity',
      itemBuilder: (context, a, _) => ListTile(
        title: Text(activityLabel(a.s('action'))),
        subtitle: Text([a.o('tenant').s('name'), a.s('actor'), formatDate(context, a.sn('at'), time: true)].where((x) => x.isNotEmpty).join(' · ')),
        onTap: a.o('tenant').iN('id') == null ? null : () => context.push('/p/restaurants/${a.o('tenant').i('id')}'),
      ),
    ),
  );
}

/// All settings tabs, edited as typed fields; SMTP with a test to any address.
class PlatformSettingsScreen extends ConsumerStatefulWidget {
  const PlatformSettingsScreen({super.key});
  @override
  ConsumerState<PlatformSettingsScreen> createState() => _PlatformSettingsScreenState();
}

class _PlatformSettingsScreenState extends ConsumerState<PlatformSettingsScreen> {
  Map<String, dynamic>? _v;
  final Map<String, dynamic> _changed = {};

  static const _tabs = <String, List<String>>{
    'general': ['name', 'support_email', 'domain', 'default_currency'],
    'signup': ['signup_open', 'signup_approval', 'signup_notify', 'turnstile_enabled', 'turnstile_site_key', 'turnstile_secret', 'upgrade_whatsapp'],
    'landing': ['brand_color', 'landing_headline', 'landing_subline'],
    'billing': ['billing_company', 'billing_address', 'billing_tax_id', 'invoice_prefix', 'invoice_footer', 'invoice_tax_rate', 'invoice_email'],
    'legal': ['terms', 'privacy'],
    'app': ['app_min_version', 'app_latest_version'],
  };

  Widget _field(String key) {
    final v = _changed.containsKey(key) ? _changed[key] : _v![key];
    if (v is bool) {
      return SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(key.replaceAll('_', ' ')),
        value: v,
        onChanged: (x) => setState(() => _changed[key] = x),
      );
    }
    final multiline = key == 'terms' || key == 'privacy' || key == 'billing_address';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: v?.toString() ?? '',
        minLines: multiline ? 6 : 1,
        maxLines: multiline ? 20 : 1,
        obscureText: key.endsWith('secret'),
        keyboardType: v is num ? const TextInputType.numberWithOptions(decimal: true) : null,
        decoration: InputDecoration(labelText: key.replaceAll('_', ' '), hintText: key.endsWith('secret') && _v!['${key}_set'] == true ? '••••••' : null),
        onChanged: (x) => _changed[key] = v is num ? num.tryParse(x) : (x.isEmpty ? null : x),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final s = ref.watch(cachedProvider('platform/settings'));
    if (_v == null && s.value != null) _v = J.data(s.value!.data).m;
    final labels = {
      'general': l.tab_general,
      'signup': l.tab_signup,
      'landing': l.tab_landing,
      'billing': l.tab_billing,
      'legal': l.tab_legal,
      'images': l.tab_images,
      'mail': l.tab_mail,
      'app': l.tab_app,
    };
    return DefaultTabController(
      length: labels.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.platformSettings),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton(
                onPressed: () async {
                  if (_changed.isEmpty) return;
                  if (await runOk(context, () => ref.read(apiProvider).put('platform/settings', data: _changed), success: l.saved)) {
                    _changed.clear();
                    ref.invalidate(cachedProvider('platform/settings'));
                    ref.invalidate(cachedProvider('mobile/config'));
                  }
                },
                child: Text(l.save),
              ),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [for (final t in labels.values) Tab(text: t)],
          ),
        ),
        body: _v == null
            ? (s.hasError ? ErrorView(error: s.error!) : const Skeleton())
            : TabBarView(
                children: [
                  for (final tab in labels.keys)
                    if (tab == 'mail')
                      const _MailSettings()
                    else if (tab == 'images')
                      _ImagesSettings(settings: _v!, onChanged: () => setState(() => _v = null))
                    else
                      ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          for (final k in _tabs[tab]!)
                            if (_v!.containsKey(k) || k.endsWith('secret')) _field(k),
                          if (tab == 'legal')
                            Wrap(
                              spacing: 8,
                              children: [
                                for (final page in ['terms', 'privacy'])
                                  OutlinedButton(
                                    onPressed: () async {
                                      if (await confirm(context, title: '${l.resetDefault} ($page)', danger: true) && context.mounted) {
                                        await runOk(context, () => ref.read(apiProvider).post('platform/settings/legal/$page/reset'), success: l.saved);
                                        setState(() => _v = null);
                                        ref.invalidate(cachedProvider('platform/settings'));
                                      }
                                    },
                                    child: Text('${l.resetDefault} · $page'),
                                  ),
                              ],
                            ),
                          if (tab == 'app')
                            _FlagsEditor(
                              flags: (_v!['app_flags'] is Map) ? (_v!['app_flags'] as Map).cast<String, dynamic>() : {},
                              onChanged: (f) => _changed['app_flags'] = f,
                            ),
                        ],
                      ),
                ],
              ),
      ),
    );
  }
}

class _FlagsEditor extends StatefulWidget {
  const _FlagsEditor({required this.flags, required this.onChanged});
  final Map<String, dynamic> flags;
  final ValueChanged<Map<String, bool>> onChanged;
  @override
  State<_FlagsEditor> createState() => _FlagsEditorState();
}

class _FlagsEditorState extends State<_FlagsEditor> {
  late final Map<String, bool> _f = {for (final e in widget.flags.entries) e.key: e.value == true};

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SectionHeader(
        context.l.appFlags,
        trailing: TextButton.icon(
          onPressed: () async {
            final c = TextEditingController();
            final name = await showDialog<String>(
              context: context,
              builder: (ctx) => AlertDialog(
                content: TextField(
                  controller: c,
                  decoration: InputDecoration(labelText: ctx.l.flagName),
                ),
                actions: [FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: Text(ctx.l.add))],
              ),
            );
            if (name != null && name.isNotEmpty) {
              setState(() => _f[name] = true);
              widget.onChanged(_f);
            }
          },
          icon: const Icon(Icons.add),
          label: Text(context.l.addFlag),
        ),
      ),
      for (final e in _f.entries)
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(e.key),
          value: e.value,
          onChanged: (v) {
            setState(() => _f[e.key] = v);
            widget.onChanged(_f);
          },
        ),
    ],
  );
}

class _MailSettings extends ConsumerStatefulWidget {
  const _MailSettings();
  @override
  ConsumerState<_MailSettings> createState() => _MailSettingsState();
}

class _MailSettingsState extends ConsumerState<_MailSettings> {
  final _c = <String, TextEditingController>{};
  String _enc = 'tls';
  bool _loaded = false;
  final _to = TextEditingController();

  TextEditingController c(String k) => _c.putIfAbsent(k, TextEditingController.new);

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final v = ref.watch(cachedProvider('platform/settings/mail')).value;
    if (!_loaded && v != null) {
      final d = J.data(v.data);
      for (final k in ['host', 'port', 'username', 'from_address', 'from_name']) {
        c(k).text = d.s(k);
      }
      _enc = d.s('encryption', 'tls');
      _loaded = true;
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: c('host'),
          decoration: InputDecoration(labelText: l.smtpHost),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: c('port'),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l.smtpPort),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: ['tls', 'ssl', 'none'].contains(_enc) ? _enc : 'tls',
                decoration: InputDecoration(labelText: l.smtpEncryption),
                items: [
                  for (final e in ['tls', 'ssl', 'none']) DropdownMenuItem(value: e, child: Text(e.toUpperCase())),
                ],
                onChanged: (x) => _enc = x!,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: c('username'),
          decoration: InputDecoration(labelText: l.smtpUsername),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: c('password'),
          obscureText: true,
          decoration: InputDecoration(labelText: l.smtpPassword, hintText: '••••••'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: c('from_address'),
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(labelText: l.smtpFromAddress),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: c('from_name'),
          decoration: InputDecoration(labelText: l.smtpFromName),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () => runOk(
            context,
            () => ref
                .read(apiProvider)
                .put(
                  'platform/settings/mail',
                  data: {
                    'host': c('host').text.trim(),
                    'port': int.tryParse(c('port').text) ?? 587,
                    'encryption': _enc,
                    'username': c('username').text.trim().isEmpty ? null : c('username').text.trim(),
                    if (c('password').text.isNotEmpty) 'password': c('password').text,
                    'from_address': c('from_address').text.trim(),
                    'from_name': c('from_name').text.trim(),
                  },
                ),
            success: l.saved,
          ),
          child: Text(l.save),
        ),
        SectionHeader(l.sendTestTo),
        TextField(
          controller: _to,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(labelText: l.email),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => runOk(context, () => ref.read(apiProvider).post('platform/settings/mail/test', data: {'to': _to.text.trim()}), success: l.testSent),
          child: Text(l.sendTest),
        ),
      ],
    );
  }
}

/// E-mail logo and the default link-preview picture.
class _ImagesSettings extends ConsumerWidget {
  const _ImagesSettings({required this.settings, required this.onChanged});
  final Map<String, dynamic> settings;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    Widget row(String title, String? url, String path) => Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              NetImage(url, width: 160, height: 84),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () async {
                  final f = await pickPhoto(context);
                  if (f == null || !context.mounted) return;
                  if (await runOk(
                    context,
                    () => ref.read(apiProvider).upload('platform/settings/$path', filePath: f.path, fileName: '$path.jpg', field: 'image'),
                    success: l.saved,
                  )) {
                    ref.invalidate(cachedProvider('platform/settings'));
                    onChanged();
                  }
                },
                child: Text(l.uploadImage),
              ),
              if (url != null)
                TextButton(
                  onPressed: () async {
                    if (await runOk(context, () => ref.read(apiProvider).delete('platform/settings/$path'))) {
                      ref.invalidate(cachedProvider('platform/settings'));
                      onChanged();
                    }
                  },
                  child: Text(l.remove),
                ),
            ],
          ),
        ],
      ),
    );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [row(l.logo, settings['logo_url'] as String?, 'logo'), row(l.tab_images, settings['share_image_url'] as String?, 'share-image')],
    );
  }
}
