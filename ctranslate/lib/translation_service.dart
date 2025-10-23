// `lib/translation_service.dart'
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class TranslationService {
  final Map<String, Map<String, String>> _dicts = {}; // key: pair like en_yo

  Future<void> loadAll() async {
    await _load('en_ha', 'assets/en_ha.json');
    await _load('ha_en', 'assets/ha_en.json');
    await _load('en_yo', 'assets/en_yo.json');
    await _load('yo_en', 'assets/yo_en.json');
    await _load('en_ig', 'assets/en_ig.json');
    await _load('ig_en', 'assets/ig_en.json');
  }

  Future<void> _load(String key, String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    final List<dynamic> parsed = json.decode(raw);
    final Map<String, String> map = {};
    for (final e in parsed) {
      // Expect entries like {"en": "hello", "yo": "ẹ n lẹ"}
      final from = e.values.firstWhere((v) => v != null, orElse: () => null);
    }
    // We'll parse generically: assume each record has two keys.
    for (final entry in parsed) {
      final keys = (entry as Map).keys.toList();
      if (keys.length >= 2) {
        final fromKey = keys[0];
        final toKey = keys[1];
        final fromVal = (entry[fromKey] ?? '').toString().trim();
        final toVal = (entry[toKey] ?? '').toString().trim();
        if (fromVal.isNotEmpty && toVal.isNotEmpty) {
          map[fromVal.toLowerCase()] = toVal;
        }
      }
    }
    _dicts[key] = map;
  }

  /// Exact lookup — returns null if not found
  String? lookup(String pairKey, String query) {
    final m = _dicts[pairKey];
    if (m == null) return null;
    return m[query.toLowerCase()];
  }

  /// Fuzzy lookup: returns best match and its value using Levenshtein distance
  MapEntry<String, String>? fuzzyLookup(String pairKey, String query, {int maxDistance = 3}) {
    final m = _dicts[pairKey];
    if (m == null || m.isEmpty) return null;
    final q = query.toLowerCase();
    String? bestKey;
    int bestScore = 9999;
    m.forEach((k, v) {
      final d = _levenshtein(k, q);
      if (d < bestScore) {
        bestScore = d;
        bestKey = k;
      }
    });
    if (bestKey != null && bestScore <= maxDistance) {
      return MapEntry(bestKey!, m[bestKey]!);
    }
    return null;
  }

  int _levenshtein(String a, String b) {
    final la = a.length;
    final lb = b.length;
    if (la == 0) return lb;
    if (lb == 0) return la;
    final d = List.generate(la + 1, (_) => List<int>.filled(lb + 1, 0));
    for (var i = 0; i <= la; i++) d[i][0] = i;
    for (var j = 0; j <= lb; j++) d[0][j] = j;
    for (var i = 1; i <= la; i++) {
      for (var j = 1; j <= lb; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        d[i][j] = [
          d[i - 1][j] + 1,
          d[i][j - 1] + 1,
          d[i - 1][j - 1] + cost
        ].reduce((x, y) => x < y ? x : y);
      }
    }
    return d[la][lb];
  }
}
