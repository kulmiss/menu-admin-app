import 'package:flutter/material.dart';

import '../../core/widgets/kit.dart';

/// The page frame inside the restaurant/platform shells.
class RestaurantScaffold extends StatelessWidget {
  const RestaurantScaffold({super.key, required this.title, required Widget this.body, this.actions, this.fab, this.bottom, this.leading})
    : subtitle = null,
      children = null,
      onRefresh = null;

  /// Tab roots (Home, Menu, Orders, More): no app bar; a large [PageTitle]
  /// scrolls with [children]. Pull to refresh when [onRefresh] is set.
  const RestaurantScaffold.large({super.key, required this.title, required List<Widget> this.children, this.subtitle, this.actions, this.fab, this.onRefresh})
    : body = null,
      bottom = null,
      leading = null;

  final String title;
  final String? subtitle;
  final Widget? body;
  final List<Widget>? children;
  final List<Widget>? actions;
  final Widget? fab;
  final PreferredSizeWidget? bottom;
  final Widget? leading;
  final RefreshCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    if (children == null) {
      return Scaffold(
        appBar: AppBar(title: Text(title), actions: actions, bottom: bottom, leading: leading),
        body: body,
        floatingActionButton: fab,
      );
    }
    final list = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        PageTitle(
          title,
          subtitle: subtitle,
          trailing: actions == null ? null : Row(mainAxisSize: MainAxisSize.min, children: actions!),
        ),
        ...children!,
      ],
    );
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: onRefresh == null ? list : RefreshIndicator(onRefresh: onRefresh!, child: list),
      ),
      floatingActionButton: fab,
    );
  }
}
