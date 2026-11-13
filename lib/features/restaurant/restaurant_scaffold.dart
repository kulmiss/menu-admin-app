import 'package:flutter/material.dart';

/// The page frame inside the restaurant/platform shells.
class RestaurantScaffold extends StatelessWidget {
  const RestaurantScaffold({super.key, required this.title, required this.body, this.actions, this.fab, this.bottom, this.leading});
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? fab;
  final PreferredSizeWidget? bottom;
  final Widget? leading;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title), actions: actions, bottom: bottom, leading: leading),
    body: body,
    floatingActionButton: fab,
  );
}
