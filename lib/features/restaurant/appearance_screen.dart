import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../app/theme.dart';
import '../../core/cache/swr.dart';
import '../../core/providers.dart';
import '../../core/util/json.dart';
import '../../core/util/photos.dart';
import '../../core/widgets/kit.dart';
import '../../core/widgets/net_image.dart';

const _flags = [
  'show_prices',
  'show_photos',
  'show_descriptions',
  'show_calories',
  'show_logo',
  'show_banner',
  'show_share',
  'show_pdf_link',
  'show_order_list',
  'show_other_branches',
];
const _palette = ['#0F766E', '#C2410C', '#B91C1C', '#7C3AED', '#1D4ED8', '#15803D', '#A16207', '#0F172A'];

/// Styles A–D, colour, font, logo/banner, switches, with a LIVE preview of
/// the real customer menu (QUESTIONS M20).
class AppearanceScreen extends ConsumerStatefulWidget {
  const AppearanceScreen({super.key});
  @override
  ConsumerState<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends ConsumerState<AppearanceScreen> {
  Map<String, dynamic>? _saved;
  Map<String, dynamic>? _v;
  bool _busy = false;
  bool _preview = false;
  double? _upload;

  bool get _dirty => _saved != null && _v != null && _diff().isNotEmpty;

  Map<String, dynamic> _diff() => {
    for (final e in _v!.entries)
      if (_saved![e.key] != e.value) e.key: e.value,
  };

  String _label(String k) => switch (k) {
    'show_prices' => context.l.show_prices,
    'show_photos' => context.l.show_photos,
    'show_descriptions' => context.l.show_descriptions,
    'show_calories' => context.l.show_calories,
    'show_logo' => context.l.show_logo,
    'show_banner' => context.l.show_banner,
    'show_share' => context.l.show_share,
    'show_pdf_link' => context.l.show_pdf_link,
    'show_order_list' => context.l.show_order_list,
    _ => context.l.show_other_branches,
  };

  String _styleLabel(String s) => switch (s) {
    'editorial' => context.l.style_editorial,
    'grid' => context.l.style_grid,
    'bistro' => context.l.style_bistro,
    _ => context.l.style_minimal,
  };

  void _load(J d) {
    final v = <String, dynamic>{
      'style': d.s('style'),
      'primary_color': d.s('primary_color', '#0F766E'),
      'font': d.s('font', 'system'),
      'banner_text': d.sn('banner_text'),
      'logo_media_id': d.o('logo').iN('id'),
      'cover_media_id': d.o('cover').iN('id'),
      for (final f in _flags) f: d.b(f, true),
    };
    _saved = {...v};
    _v = v;
  }

  Future<void> _save() async {
    final t = ref.read(tenantProvider)!;
    setState(() => _busy = true);
    final ok = await runOk(context, () async {
      final r = await ref.read(apiProvider).put(tenantPath(t.id, 'appearance'), data: _v);
      _load(J.data(r));
      ref.invalidate(cachedProvider(tenantPath(t.id, 'appearance')));
      return null;
    }, success: context.l.saved);
    if (mounted) setState(() => _busy = ok ? false : false);
  }

  Future<void> _pickImage(String key, J data) async {
    final t = ref.read(tenantProvider)!;
    final banner = key == 'cover_media_id';
    final ratio = banner ? data.o('banner').o(_v!['style'] as String).d('ratio', 2.5) : 1.0;
    final f = await pickPhoto(context, aspect: CropAspectRatio(ratioX: ratio, ratioY: 1));
    if (f == null || !mounted) return;
    setState(() => _upload = 0);
    try {
      final r = await ref
          .read(apiProvider)
          .upload(
            tenantPath(t.id, 'media'),
            filePath: f.path,
            fileName: '$key.jpg',
            fields: {if (banner) 'purpose': 'banner'},
            onProgress: (p) => setState(() => _upload = p),
          );
      final media = J.data(r);
      setState(() {
        _v![key] = media.i('id');
        _thumbs[key] = media.photo('x', width: 640) ?? photoUrl(media.m, width: 640);
      });
    } catch (e) {
      if (mounted) showSnack(context, errorText(context, e));
    } finally {
      if (mounted) setState(() => _upload = null);
    }
  }

  final Map<String, String?> _thumbs = {};

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(tenantProvider)!;
    final l = context.l;
    final wide = MediaQuery.sizeOf(context).width >= 840;
    final async = ref.watch(cachedProvider(tenantPath(t.id, 'appearance')));
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (did, _) async {
        if (!did && await confirm(context, title: l.unsavedTitle, action: l.discard, danger: true) && context.mounted) {
          setState(() => _v = {..._saved!});
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.appearance),
          actions: [
            if (!wide)
              IconButton(
                tooltip: l.livePreview,
                isSelected: _preview,
                icon: const Icon(Icons.visibility_outlined),
                selectedIcon: const Icon(Icons.edit_outlined),
                onPressed: () => setState(() => _preview = !_preview),
              ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton(onPressed: _dirty && !_busy && _upload == null ? _save : null, child: Text(l.save)),
            ),
          ],
        ),
        body: async.when(
          loading: () => const Skeleton(),
          error: (e, _) => ErrorView(error: e),
          data: (c) {
            final d = J.data(c.data);
            if (_v == null) _load(d);
            final form = _form(context, d);
            final preview = _LivePreview(values: _v!);
            if (wide) {
              return Row(
                children: [
                  Expanded(child: form),
                  const VerticalDivider(width: 1),
                  SizedBox(width: 420, child: preview),
                ],
              );
            }
            return _preview ? preview : form;
          },
        ),
      ),
    );
  }

  Widget _form(BuildContext context, J d) {
    final l = context.l;
    final styles = [for (final s in (d['styles'] as List? ?? const [])) '$s'];
    final colour = parseHex(_v!['primary_color'] as String) ?? AppColors.teal;
    final lowContrast = contrastRatio(colour, Colors.white) < 4.5;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
      children: [
        if (_dirty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              l.unsavedChanges,
              style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.w600),
            ),
          ),
        SectionHeader(l.menuStyle),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in ['editorial', 'grid', 'bistro', 'minimal'])
              ChoiceChip(
                label: Text(_styleLabel(s)),
                avatar: styles.contains(s) ? null : const Icon(Icons.lock_outline, size: 16),
                selected: _v!['style'] == s,
                onSelected: (_) => styles.contains(s) ? setState(() => _v!['style'] = s) : showUpgradeSheet(context),
              ),
          ],
        ),
        SectionHeader(l.brandColour),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final hex in _palette)
              Semantics(
                label: hex,
                selected: _v!['primary_color'].toString().toUpperCase() == hex,
                button: true,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => setState(() => _v!['primary_color'] = hex),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: parseHex(hex),
                      shape: BoxShape.circle,
                      border: Border.all(width: 3, color: _v!['primary_color'].toString().toUpperCase() == hex ? context.colors.onSurface : Colors.transparent),
                    ),
                  ),
                ),
              ),
            SizedBox(
              width: 130,
              child: TextFormField(
                key: ValueKey(_v!['primary_color']),
                initialValue: _v!['primary_color'] as String,
                decoration: const InputDecoration(labelText: 'Hex', isDense: true),
                onFieldSubmitted: (v) => RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(v) ? setState(() => _v!['primary_color'] = v.toUpperCase()) : null,
              ),
            ),
          ],
        ),
        if (lowContrast)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(l.contrastWarning, style: TextStyle(color: context.colors.onSurfaceVariant, fontSize: 13)),
          ),
        SectionHeader(l.font),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'system', label: Text(l.font_system)),
            ButtonSegment(value: 'serif', label: Text(l.font_serif)),
            ButtonSegment(value: 'rounded', label: Text(l.font_rounded)),
          ],
          selected: {_v!['font'] as String},
          onSelectionChanged: (s) => setState(() => _v!['font'] = s.first),
        ),
        SectionHeader(l.logo),
        _ImageRow(
          url: _thumbs['logo_media_id'] ?? (_v!['logo_media_id'] == null ? null : d.photo('logo')),
          busy: _upload != null,
          onPick: () => _pickImage('logo_media_id', d),
          onRemove: () => setState(() => _v!['logo_media_id'] = null),
        ),
        SectionHeader(l.banner),
        _ImageRow(
          url: _thumbs['cover_media_id'] ?? (_v!['cover_media_id'] == null ? null : d.photo('cover', width: 640)),
          wide: true,
          busy: _upload != null,
          onPick: () => _pickImage('cover_media_id', d),
          onRemove: () => setState(() => _v!['cover_media_id'] = null),
        ),
        if (_upload != null) LinearProgressIndicator(value: _upload),
        DropdownButtonFormField<String?>(
          initialValue: _v!['banner_text'] as String?,
          decoration: InputDecoration(labelText: l.bannerText),
          items: [
            DropdownMenuItem(value: 'over', child: Text(l.bannerOver)),
            DropdownMenuItem(value: 'under', child: Text(l.bannerUnder)),
            DropdownMenuItem(value: null, child: Text(l.bannerNone)),
          ],
          onChanged: (v) => setState(() => _v!['banner_text'] = v),
        ),
        SectionHeader(l.showOnMenu),
        for (final f in _flags)
          SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(_label(f)), value: _v![f] as bool, onChanged: (v) => setState(() => _v![f] = v)),
      ],
    );
  }
}

class _ImageRow extends StatelessWidget {
  const _ImageRow({required this.url, required this.onPick, required this.onRemove, this.wide = false, this.busy = false});
  final String? url;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  final bool wide;
  final bool busy;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      NetImage(url, width: wide ? 160 : 72, height: 72),
      const SizedBox(width: 12),
      OutlinedButton(onPressed: busy ? null : onPick, child: Text(context.l.change)),
      if (url != null) TextButton(onPressed: busy ? null : onRemove, child: Text(context.l.remove)),
    ],
  );
}

/// The real guest page with the unsaved settings (`appearance/preview`).
class _LivePreview extends ConsumerStatefulWidget {
  const _LivePreview({required this.values});
  final Map<String, dynamic> values;
  @override
  ConsumerState<_LivePreview> createState() => _LivePreviewState();
}

class _LivePreviewState extends ConsumerState<_LivePreview> {
  // The preview's own script needs JavaScript; nothing else is allowed (SECURITY_REPORT.md L8):
  // no JS bridge, no navigation away (links do nothing), no file or content:// access, no mixed content.
  late final WebViewController _web = _hardened(
    WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (r) => allowPreviewNavigation(r.url, ref.read(apiProvider).siteUrl) ? NavigationDecision.navigate : NavigationDecision.prevent,
        ),
      ),
  );

  static WebViewController _hardened(WebViewController c) {
    final p = c.platform;
    if (p is AndroidWebViewController) {
      unawaited(p.setAllowFileAccess(false));
      unawaited(p.setAllowContentAccess(false));
      unawaited(p.setMixedContentMode(MixedContentMode.neverAllow));
    }
    return c;
  }

  Timer? _debounce;
  String? _last;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(covariant _LivePreview old) {
    super.didUpdateWidget(old);
    _schedule();
  }

  void _schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _load);
  }

  Future<void> _load() async {
    final q = {
      for (final e in widget.values.entries)
        if (e.value != null) e.key: e.value is bool ? (e.value as bool ? '1' : '0') : '${e.value}',
    };
    final key = q.toString();
    if (key == _last) return;
    _last = key;
    final t = ref.read(tenantProvider)!;
    final api = ref.read(apiProvider);
    if (mounted) setState(() => _loading = true);
    try {
      final r = await api.dio.get<String>(
        tenantPath(t.id, 'appearance/preview'),
        queryParameters: q,
        options: Options(responseType: ResponseType.plain, headers: {'Accept': 'text/html'}),
      );
      await _web.loadHtmlString(r.data ?? '', baseUrl: api.siteUrl);
    } catch (_) {
      // Keep the last preview on screen.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      WebViewWidget(controller: _web),
      if (_loading) const LinearProgressIndicator(),
    ],
  );
}

/// Only loading the preview itself (about:blank, or exactly the site address it is
/// loaded under, which iOS reports); every link inside it is blocked (SECURITY_REPORT.md L8).
@visibleForTesting
bool allowPreviewNavigation(String url, String siteUrl) => url.startsWith('about:') || url == siteUrl;
