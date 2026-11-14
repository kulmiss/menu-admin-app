import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/env.dart';
import '../../core/api/api_error.dart';
import '../../core/app_config.dart';
import '../../core/auth/auth_repository.dart';
import '../../core/providers.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/kit.dart';

/// Sign-in and the two-factor step (backend QUESTIONS #187).
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});
  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();
  String? _challenge;
  bool _recovery = false;
  bool _busy = false;
  bool _showPassword = false;
  String? _error;
  Map<String, String?> _fieldErrors = {};
  int _logoTaps = 0;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
      _fieldErrors = {};
    });
    final auth = ref.read(authRepositoryProvider);
    try {
      if (_challenge == null) {
        final r = await auth.login(_email.text, _password.text);
        switch (r) {
          case LoggedIn(:final token):
            await ref.read(sessionProvider.notifier).signIn(token);
          case NeedsTwoFactor(:final challenge):
            setState(() => _challenge = challenge);
        }
      } else {
        final token = await auth.twoFactor(_challenge!, code: _recovery ? null : _code.text, recoveryCode: _recovery ? _code.text : null);
        await ref.read(sessionProvider.notifier).signIn(token);
      }
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.kind == ApiErrorKind.notFound && _challenge != null) {
          _challenge = null;
          _code.clear();
          _error = context.l.challengeExpired;
        } else if (e.kind == ApiErrorKind.validation) {
          _fieldErrors = {for (final f in e.fieldErrors.keys) f: e.field(f)};
        } else {
          _error = errorText(context, e);
        }
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changeServer() async {
    final c = TextEditingController(text: ref.read(apiProvider).siteUrl);
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l.serverAddress),
        content: TextField(
          controller: c,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(hintText: ctx.l.serverHint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: Text(ctx.l.save)),
        ],
      ),
    );
    if (v != null && v.isNotEmpty) {
      ref.read(apiProvider).setServer(v);
      await ref.read(tokenStoreProvider).write('server', v);
      if (mounted) showSnack(context, v);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final config = ref.watch(appConfigProvider);
    final twoFactor = _challenge != null;
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AutofillGroup(
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: GestureDetector(
                          onTap: Env.canChangeServer ? () => ++_logoTaps >= 5 ? (_logoTaps = 0, _changeServer()) : null : null,
                          child: const AppLogo(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        twoFactor ? l.twoFactorTitle : l.signInTitle,
                        textAlign: TextAlign.center,
                        style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        twoFactor ? l.twoFactorBody : l.signInSubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.colors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 28),
                      if (_error != null) ...[
                        Semantics(
                          liveRegion: true,
                          child: Text(_error!, style: TextStyle(color: context.colors.error)),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (!twoFactor) ...[
                        TextFormField(
                          key: const Key('email'),
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email, AutofillHints.username],
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(labelText: l.email, errorText: _fieldErrors['email']),
                          validator: (v) => (v == null || !v.contains('@')) ? l.requiredField : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          key: const Key('password'),
                          controller: _password,
                          obscureText: !_showPassword,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: l.password,
                            errorText: _fieldErrors['password'],
                            suffixIcon: IconButton(
                              tooltip: l.password,
                              icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _showPassword = !_showPassword),
                            ),
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? l.requiredField : null,
                        ),
                      ] else
                        TextFormField(
                          key: const Key('code'),
                          controller: _code,
                          autofocus: true,
                          keyboardType: _recovery ? TextInputType.text : TextInputType.number,
                          autofillHints: const [AutofillHints.oneTimeCode],
                          inputFormatters: _recovery ? null : [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                          style: _recovery ? null : const TextStyle(fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.w600),
                          textAlign: _recovery ? TextAlign.start : TextAlign.center,
                          onChanged: (v) => !_recovery && v.length == 6 ? _submit() : null,
                          decoration: InputDecoration(labelText: _recovery ? l.recoveryCode : l.twoFactorCode, errorText: _fieldErrors['code']),
                          validator: (v) => (v == null || v.isEmpty) ? l.requiredField : null,
                        ),
                      const SizedBox(height: 20),
                      FilledButton(
                        key: const Key('submit'),
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(twoFactor ? l.verify : l.signIn),
                      ),
                      const SizedBox(height: 8),
                      if (twoFactor)
                        TextButton(
                          onPressed: () => setState(() {
                            _recovery = !_recovery;
                            _code.clear();
                          }),
                          child: Text(_recovery ? l.useAuthenticatorCode : l.useRecoveryCode),
                        )
                      else
                        TextButton(
                          onPressed: () => openExternal(context, config?.link('forgot_password') ?? '${ref.read(apiProvider).siteUrl}auth/forgot-password'),
                          child: Text(l.forgotPassword),
                        ),
                      const SizedBox(height: 24),
                      Text(
                        l.newRestaurant,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: context.colors.onSurfaceVariant),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () => openExternal(context, config?.link('privacy') ?? '${ref.read(apiProvider).siteUrl}privacy'),
                            child: Text(l.privacy),
                          ),
                          TextButton(
                            onPressed: () => openExternal(context, config?.link('terms') ?? '${ref.read(apiProvider).siteUrl}terms'),
                            child: Text(l.terms),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
