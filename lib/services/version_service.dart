class VersionService {
  VersionService._internal();
  static final VersionService instance = VersionService._internal();

  /// Simple semver comparator: returns true if [current] is older than [minimum].
  bool isOlderThan(String current, String minimum) {
    final c = current.split('.').map(int.parse).toList();
    final m = minimum.split('.').map(int.parse).toList();
    for (var i = 0; i < 3; i++) {
      final cv = i < c.length ? c[i] : 0;
      final mv = i < m.length ? m[i] : 0;
      if (cv != mv) return cv < mv;
    }
    return false;
  }
}