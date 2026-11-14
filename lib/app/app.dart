import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/platform/push.dart';
import '../core/providers.dart';
import '../features/auth/gates.dart';
import '../l10n/app_localizations.dart';
import 'app_identity.dart';
import 'router.dart';
import 'theme.dart';

class MenuAdminApp extends ConsumerStatefulWidget {
  const MenuAdminApp({super.key});
  @override
  ConsumerState<MenuAdminApp> createState() => _MenuAdminAppState();
}

class _MenuAdminAppState extends ConsumerState<MenuAdminApp> {
  @override
  void initState() {
    super.initState();
    final push = ref.read(pushServiceProvider);
    push.pendingLink.addListener(() {
      final path = push.pendingLink.value;
      if (path == null) return;
      push.pendingLink.value = null;
      ref.read(routerProvider).go(path);
    });
    push.foreground.addListener(_showForegroundPush);
  }

  void _showForegroundPush() {
    final msg = ref.read(pushServiceProvider).foreground.value;
    final n = msg?.notification;
    if (n == null) return;
    final messenger = _messengerKey.currentState;
    messenger?.showSnackBar(
      SnackBar(
        content: Text([n.title, n.body].whereType<String>().join('\n')),
        action: msg!.data['link'] == null
            ? null
            : SnackBarAction(label: 'Open', onPressed: () => ref.read(pushServiceProvider).pendingLink.value = msg.data['link'] as String),
      ),
    );
  }

  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    final GoRouter router = ref.watch(routerProvider);
    final accent = accentFor(parseHex(ref.watch(tenantProvider.select((t) => t?.json['primary_color'] as String?))));
    return MaterialApp.router(
      title: AppIdentity.name,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _messengerKey,
      theme: buildTheme(Brightness.light, accent: accent),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      themeAnimationDuration: MediaQuery.maybeDisableAnimationsOf(context) ?? false ? Duration.zero : const Duration(milliseconds: 200),
      localizationsDelegates: const [
        L.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: L.supportedLocales,
      routerConfig: router,
      builder: (context, child) => AppGates(child: child ?? const SizedBox.shrink()),
    );
  }
}
