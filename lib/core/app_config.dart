import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cache/swr.dart';

/// `GET mobile/config` (backend QUESTIONS #190), cached like any answer.
class AppConfig {
  AppConfig(this.json);
  final Map<String, dynamic> json;

  String get minVersion => json['min_version'] as String? ?? '0.0.0';
  String get latestVersion => json['latest_version'] as String? ?? '0.0.0';
  bool flag(String name) => (json['flags'] as Map?)?[name] == true;
  Map<String, dynamic> get links => (json['links'] as Map?)?.cast<String, dynamic>() ?? const {};
  String? link(String name) => links[name] as String?;
}

final appConfigProvider = Provider<AppConfig?>((ref) {
  final c = ref.watch(cachedProvider('mobile/config')).value;
  final data = (c?.data as Map?)?['data'];
  return data is Map ? AppConfig(data.cast<String, dynamic>()) : null;
});

/// Compares x.y.z versions (build numbers ignored).
int compareVersions(String a, String b) {
  List<int> parts(String v) => v.split('+').first.split('.').map((p) => int.tryParse(p) ?? 0).toList()..addAll([0, 0, 0]);
  final pa = parts(a), pb = parts(b);
  for (var i = 0; i < 3; i++) {
    if (pa[i] != pb[i]) return pa[i].compareTo(pb[i]);
  }
  return 0;
}
