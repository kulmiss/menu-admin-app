import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/cache/swr.dart';
import '../../core/providers.dart';
import '../../core/util/json.dart';
import '../../core/widgets/adaptive_shell.dart';
import '../../core/widgets/kit.dart';
import '../../core/widgets/net_image.dart';
import 'dish_editor_screen.dart';
import 'menu_data.dart';
import 'menu_settings.dart';
import 'restaurant_scaffold.dart';

/// Menu editor: menus → categories → dishes, quick sold-out switches,
/// drag-to-reorder; on tablets the dish opens beside the list.
class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key, this.menuId});
  final int? menuId;

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  int? _menuId;
  int? _selectedDish;
  bool _reorder = false;

  @override
  void initState() {
    super.initState();
    _menuId = widget.menuId;
  }

  @override
  Widget build(BuildContext context) {
    final tenant = ref.watch(tenantProvider)!;
    final can = ref.watch(canProvider);
    final menusPath = tenantPath(tenant.id, 'menus');
    final menus = ref.watch(cachedProvider(menusPath));
    final list = menus.value == null ? <J>[] : J.dataList(menus.value!.data);
    final menuId = _menuId ?? (list.isNotEmpty ? list.first.i('id') : null);
    final menu = list.where((m) => m.i('id') == menuId).firstOrNull;
    final wide = TwoPane.isWide(context);

    return RestaurantScaffold(
      title: context.l.navMenu,
      actions: [
        IconButton(tooltip: context.l.allDishes, icon: const Icon(Icons.table_rows_outlined), onPressed: () => context.push('/r/${tenant.id}/all-dishes')),
        if (can.manageMenu && menu != null)
          IconButton(
            tooltip: _reorder ? context.l.reorderDone : context.l.reorder,
            icon: Icon(_reorder ? Icons.check : Icons.swap_vert),
            onPressed: () => setState(() => _reorder = !_reorder),
          ),
        if (can.manageMenu) MenuActions(menu: menu, onChanged: (id) => setState(() => _menuId = id)),
      ],
      fab: can.manageMenu && menu != null && !_reorder
          ? FloatingActionButton.extended(
              onPressed: () => _openDish(context, tenant.id, null, menuId: menuId),
              icon: const Icon(Icons.add),
              label: Text(context.l.dish),
            )
          : null,
      body: menus.when(
        skipLoadingOnRefresh: true,
        loading: () => const Skeleton(),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(cachedProvider(menusPath))),
        data: (_) {
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.restaurant_menu,
              title: context.l.noMenus,
              body: context.l.noMenusBody,
              action: can.manageMenu
                  ? FilledButton(onPressed: () => createMenu(context, ref).then((id) => setState(() => _menuId = id)), child: Text(context.l.newMenu))
                  : null,
            );
          }
          final tree = Column(
            children: [
              if (list.length > 1 || can.manageMenu)
                SizedBox(
                  height: 56,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    children: [
                      for (final m in list)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text([m.t('name'), if (!m.b('is_visible', true)) '·  ${context.l.hide}'].join(' ')),
                            selected: m.i('id') == menuId,
                            onSelected: (_) => setState(() {
                              _menuId = m.i('id');
                              _selectedDish = null;
                            }),
                          ),
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: MenuTree(
                  menuId: menuId!,
                  reorder: _reorder,
                  selectedDish: _selectedDish,
                  onDish: (id) => wide ? setState(() => _selectedDish = id) : _openDish(context, tenant.id, id),
                ),
              ),
            ],
          );
          return TwoPane(
            listWidth: 420,
            list: tree,
            detail: _selectedDish == null
                ? null
                : DishEditor(key: ValueKey(_selectedDish), dishId: _selectedDish, embedded: true, onClosed: () => setState(() => _selectedDish = null)),
            emptyDetail: EmptyState(icon: Icons.touch_app_outlined, title: context.l.edit),
          );
        },
      ),
    );
  }

  void _openDish(BuildContext context, int tenantId, int? id, {int? menuId}) {
    context.push(id == null ? '/r/$tenantId/dishes/new${menuId != null ? '?menu=$menuId' : ''}' : '/r/$tenantId/dishes/$id');
  }
}

/// Categories and dishes of one menu.
class MenuTree extends ConsumerWidget {
  const MenuTree({super.key, required this.menuId, required this.onDish, this.reorder = false, this.selectedDish});
  final int menuId;
  final bool reorder;
  final int? selectedDish;
  final ValueChanged<int> onDish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenant = ref.watch(tenantProvider)!;
    final path = tenantPath(tenant.id, 'menus/$menuId/tree');
    final can = ref.watch(canProvider);
    final overrides = ref.watch(soldOutProvider);
    return CachedView(
      path: path,
      builder: (context, data, _) {
        final cats = J.data(data).list('categories');
        if (cats.isEmpty) {
          return ListView(
            children: [
              EmptyState(
                icon: Icons.category_outlined,
                title: context.l.noCategories,
                body: context.l.noCategoriesBody,
                action: can.manageMenu ? FilledButton(onPressed: () => createCategory(context, ref, menuId), child: Text(context.l.newCategory)) : null,
              ),
            ],
          );
        }
        if (reorder) return _ReorderCategories(menuId: menuId, categories: cats, treePath: path);
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 96),
          itemCount: cats.length + (can.manageMenu ? 1 : 0),
          itemBuilder: (context, i) {
            if (i == cats.length) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton.icon(
                  onPressed: () => createCategory(context, ref, menuId),
                  icon: const Icon(Icons.add),
                  label: Text(context.l.newCategory),
                ),
              );
            }
            final c = cats[i];
            final items = c.list('items');
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader(
                  [c.t('name'), if (!c.b('is_visible', true)) '(${context.l.hiddenFromGuests})'].join(' '),
                  trailing: can.manageMenu ? CategoryActions(category: c, menuId: menuId) : null,
                ),
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(context.l.noDishes, style: TextStyle(color: context.colors.onSurfaceVariant)),
                  ),
                for (final it in items)
                  DishRow(
                    item: it,
                    currency: tenant.currency,
                    selected: it.i('id') == selectedDish,
                    soldOut: overrides[it.i('id')] ?? it.b('is_sold_out'),
                    onTap: () => onDish(it.i('id')),
                    onSoldOut: can.toggleSoldOut ? (v) => ref.read(soldOutProvider.notifier).set(context, it.i('id'), v) : null,
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class DishRow extends StatelessWidget {
  const DishRow({super.key, required this.item, required this.currency, required this.soldOut, required this.onTap, this.onSoldOut, this.selected = false});
  final J item;
  final String currency;
  final bool soldOut;
  final bool selected;
  final VoidCallback onTap;
  final ValueChanged<bool>? onSoldOut;

  @override
  Widget build(BuildContext context) {
    final hidden = !item.b('is_visible', true);
    final price = priceLine(item, currency);
    return Material(
      color: selected ? context.colors.surfaceContainerHigh : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              NetImage(item.photo('media'), size: 52, semanticLabel: item.t('name')),
              const SizedBox(width: 12),
              Expanded(
                child: Opacity(
                  opacity: soldOut || hidden ? .55 : 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.t('name'),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [if (soldOut) context.l.soldOut, if (hidden) context.l.hiddenFromGuests, if (price.isNotEmpty) price].join(' · '),
                        style: TextStyle(fontSize: 13, color: soldOut ? context.colors.error : context.colors.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              if (onSoldOut != null)
                Semantics(
                  label: '${item.t('name')}: ${context.l.available}',
                  child: Switch(value: !soldOut, onChanged: (v) => onSoldOut!(!v)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReorderCategories extends ConsumerStatefulWidget {
  const _ReorderCategories({required this.menuId, required this.categories, required this.treePath});
  final int menuId;
  final List<J> categories;
  final String treePath;

  @override
  ConsumerState<_ReorderCategories> createState() => _ReorderCategoriesState();
}

class _ReorderCategoriesState extends ConsumerState<_ReorderCategories> {
  late List<J> _cats = [...widget.categories];

  @override
  void didUpdateWidget(covariant _ReorderCategories old) {
    super.didUpdateWidget(old);
    _cats = [...widget.categories];
  }

  Future<void> _save(List<J> order) async {
    final t = ref.read(tenantProvider)!;
    setState(() => _cats = order);
    await runAction(context, () async {
      await ref
          .read(apiProvider)
          .post(
            tenantPath(t.id, 'categories/reorder'),
            data: {
              'menu_id': widget.menuId,
              'ids': [for (final c in order) c.i('id')],
            },
          );
      ref.invalidate(cachedProvider(widget.treePath));
    });
  }

  @override
  Widget build(BuildContext context) => ReorderableListView.builder(
    padding: const EdgeInsets.only(bottom: 40),
    header: Padding(
      padding: const EdgeInsets.all(16),
      child: Text(context.l.dragToReorder, style: TextStyle(color: context.colors.onSurfaceVariant)),
    ),
    itemCount: _cats.length,
    onReorderItem: (from, to) {
      final next = [..._cats];
      final c = next.removeAt(from);
      next.insert(to, c);
      _save(next);
    },
    itemBuilder: (context, i) => ListTile(
      key: ValueKey(_cats[i].i('id')),
      leading: const Icon(Icons.drag_indicator),
      title: Text(_cats[i].t('name')),
      subtitle: Text('${_cats[i].list('items').length} ${context.l.dishes.toLowerCase()}'),
      trailing: TextButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => _ReorderDishes(category: _cats[i], treePath: widget.treePath),
          ),
        ),
        child: Text(context.l.dishes),
      ),
    ),
  );
}

class _ReorderDishes extends ConsumerStatefulWidget {
  const _ReorderDishes({required this.category, required this.treePath});
  final J category;
  final String treePath;

  @override
  ConsumerState<_ReorderDishes> createState() => _ReorderDishesState();
}

class _ReorderDishesState extends ConsumerState<_ReorderDishes> {
  late List<J> _items = widget.category.list('items');

  Future<void> _save(List<J> order) async {
    final t = ref.read(tenantProvider)!;
    setState(() => _items = order);
    await runAction(context, () async {
      await ref
          .read(apiProvider)
          .post(
            tenantPath(t.id, 'items/reorder'),
            data: {
              'category_id': widget.category.i('id'),
              'ids': [for (final c in order) c.i('id')],
            },
          );
      ref.invalidate(cachedProvider(widget.treePath));
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.category.t('name'))),
    body: ReorderableListView.builder(
      itemCount: _items.length,
      onReorderItem: (from, to) {
        final next = [..._items];
        final c = next.removeAt(from);
        next.insert(to, c);
        _save(next);
      },
      itemBuilder: (context, i) => ListTile(
        key: ValueKey(_items[i].i('id')),
        leading: NetImage(_items[i].photo('media'), size: 40),
        title: Text(_items[i].t('name')),
        trailing: const Icon(Icons.drag_indicator),
      ),
    ),
  );
}
