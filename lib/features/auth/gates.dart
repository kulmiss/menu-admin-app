import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_config.dart';
import '../../core/platform/app_lock.dart';
import '../../core/platform/secure_screen.dart';
import '../../core/platform/updates.dart';
import '../../core/providers.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/kit.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).colorScheme.surface,
    body: const Center(child: AppLogo(size: 96)),
  );
}

class NoRestaurantScreen extends ConsumerWidget {
  const NoRestaurantScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(sessionProvider).me;
    final unverified = me != null && !me.emailVerified;
    return Scaffold(
      body: SafeArea(
        child: EmptyState(
          icon: unverified ? Icons.mark_email_unread_outlined : Icons.storefront_outlined,
          title: unverified ? context.l.emailUnverifiedTitle : context.l.noRestaurantTitle,
          body: unverified ? context.l.emailUnverifiedBody(me.email) : context.l.noRestaurantBody,
          action: Column(
            children: [
              if (unverified) FilledButton(onPressed: () => ref.read(sessionProvider.notifier).refreshMe(), child: Text(context.l.iConfirmed)),
              TextButton(onPressed: () => ref.read(sessionProvider.notifier).signOut(), child: Text(context.l.signOut)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wraps the whole app: "Update required", the app lock, and the
/// "unverified e-mail" gate (like the web's "Check your inbox").
class AppGates extends ConsumerStatefulWidget {
  const AppGates({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<AppGates> createState() => _AppGatesState();
}

class _AppGatesState extends ConsumerState<AppGates> with WidgetsBindingObserver {
  bool _cover = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(appLockProvider.notifier).onLifecycle(state);
    final lockOn = ref.read(appLockProvider).enabled;
    // Also cover a secret screen (two-factor key, recovery codes) in the app switcher (M13).
    final secret = SecureScreens.open.value > 0;
    setState(() => _cover = (lockOn || secret) && state != AppLifecycleState.resumed);
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final version = ref.watch(appVersionProvider);
    final lock = ref.watch(appLockProvider);
    final signedIn = ref.watch(sessionProvider.select((s) => s.status == SessionStatus.signedIn));
    if (config != null && compareVersions(version, config.minVersion) < 0) return const _UpdateRequired();
    return Stack(
      children: [
        widget.child,
        if (signedIn && lock.enabled && lock.locked) const Positioned.fill(child: LockScreen()),
        if (_cover)
          Positioned.fill(
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surface,
              child: const Center(child: AppLogo()),
            ),
          ),
      ],
    );
  }
}

class _UpdateRequired extends StatefulWidget {
  const _UpdateRequired();
  @override
  State<_UpdateRequired> createState() => _UpdateRequiredState();
}

class _UpdateRequiredState extends State<_UpdateRequired> {
  @override
  void initState() {
    super.initState();
    checkPlayUpdate(mustUpdate: true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: EmptyState(
        icon: Icons.system_update,
        title: context.l.updateRequiredTitle,
        body: context.l.updateRequiredBody,
        action: FilledButton(onPressed: () => checkPlayUpdate(mustUpdate: true), child: Text(context.l.updateNow)),
      ),
    ),
  );
}

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});
  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _pin = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bio());
  }

  Future<void> _bio() async {
    final lock = ref.read(appLockProvider);
    if (lock.biometrics && await ref.read(appLockProvider.notifier).canUseBiometrics() && mounted) {
      await ref.read(appLockProvider.notifier).biometric(context.l.lockedTitle);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLogo(),
                const SizedBox(height: 16),
                Text(context.l.lockedTitle, style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                TextField(
                  controller: _pin,
                  obscureText: true,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                  style: const TextStyle(fontSize: 24, letterSpacing: 10),
                  decoration: InputDecoration(labelText: context.l.enterPin, errorText: _error),
                  onSubmitted: (_) => _check(),
                ),
                const SizedBox(height: 12),
                FilledButton(onPressed: _check, child: Text(context.l.unlock)),
                TextButton.icon(onPressed: _bio, icon: const Icon(Icons.fingerprint), label: Text(context.l.useBiometrics)),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> _check() async {
    final ok = await ref.read(appLockProvider.notifier).checkPin(_pin.text);
    if (!ok && mounted) setState(() => _error = context.l.pinWrong);
  }
}
