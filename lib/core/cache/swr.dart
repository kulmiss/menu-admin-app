import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_error.dart';
import '../providers.dart';

/// An API answer with where it came from (PLAN.md §6).
class Cached<T> {
  const Cached(this.data, {required this.fetchedAt, this.fromCache = false, this.error});

  final T data;
  final DateTime fetchedAt;

  /// Shown from the device while the network answer is on its way.
  final bool fromCache;

  /// The refresh failed (e.g. offline); [data] is the last good answer.
  final ApiError? error;

  Cached<T> copyWith({T? data, bool? fromCache, ApiError? error}) =>
      Cached(data ?? this.data, fetchedAt: fetchedAt, fromCache: fromCache ?? this.fromCache, error: error);
}

/// How long an answer stays in memory after its screen closes (0 in tests).
final cacheKeepAliveProvider = Provider<Duration>((ref) => const Duration(minutes: 3));

/// Stale-while-revalidate read of a GET path: the saved answer at once (if
/// any), then the network answer. Errors keep the saved answer on screen.
final cachedProvider = StreamProvider.autoDispose.family<Cached<dynamic>, String>((ref, path) async* {
  final db = ref.watch(cacheDbProvider);
  final scope = ref.watch(sessionProvider.select((s) => s.scope));
  final api = ref.watch(apiProvider);
  // Keep a list alive a little while after leaving it, so going back is instant.
  final link = ref.keepAlive();
  final keep = ref.read(cacheKeepAliveProvider);
  Timer? timer;
  ref.onCancel(() => keep == Duration.zero ? link.close() : timer = Timer(keep, link.close));
  ref.onResume(() => timer?.cancel());
  ref.onDispose(() => timer?.cancel());

  final saved = await db.read(scope, path);
  Cached<dynamic>? last;
  if (saved != null) {
    last = Cached<dynamic>(jsonDecode(saved.json), fetchedAt: saved.fetchedAt, fromCache: true);
    yield last;
  }
  try {
    final data = await api.get(path);
    unawaited(db.write(scope, path, jsonEncode(data)));
    yield Cached<dynamic>(data, fetchedAt: DateTime.now());
  } on ApiError catch (e) {
    if (last == null) rethrow;
    yield last.copyWith(error: e);
  }
});

/// Helpers for screens.
extension CacheRefresh on WidgetRef {
  /// Pull-to-refresh: fetch again and wait for the answer.
  Future<void> refreshPath(String path) async {
    invalidate(cachedProvider(path));
    try {
      await read(cachedProvider(path).future);
    } catch (_) {}
  }
}

/// Drops saved answers whose path starts with [prefix] and reloads open screens.
Future<void> invalidatePrefix(Object ref, String prefix) async {
  final (session, db) = switch (ref) {
    final Ref r => (r.read(sessionProvider), r.read(cacheDbProvider)),
    final WidgetRef r => (r.read(sessionProvider), r.read(cacheDbProvider)),
    _ => throw ArgumentError('ref'),
  };
  await db.removePrefix(session.scope, prefix);
}

/// Writes a changed answer into the cache (optimistic updates).
Future<void> writeCache(WidgetRef ref, String path, Object? data) async {
  final scope = ref.read(sessionProvider).scope;
  await ref.read(cacheDbProvider).write(scope, path, jsonEncode(data));
}
