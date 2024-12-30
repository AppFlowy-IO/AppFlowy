import 'dart:math';

int levenshtein(String s, String t, {bool caseSensitive = true}) {
  if (!caseSensitive) {
    s = s.toLowerCase();
    t = t.toLowerCase();
  }

  if (s == t) return 0;

  final v0 = List<int>.generate(t.length + 1, (i) => i);
  final v1 = List<int>.filled(t.length + 1, 0);

  for (var i = 0; i < s.length; i++) {
    v1[0] = i + 1;

    for (var j = 0; j < t.length; j++) {
      final cost = (s[i] == t[j]) ? 0 : 1;
      v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
    }

    v0.setAll(0, v1);
  }

  return v1[t.length];
}
