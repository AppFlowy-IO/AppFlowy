import 'dart:math';

import 'package:flutter/foundation.dart';

typedef Path = List<int>;

bool pathEquals(Path path1, Path path2) {
  return listEquals(path1, path2);
}

/// Returns true if path1 >= path2, otherwise returns false.
/// TODO: Rename this function.
bool pathGreaterOrEquals(Path path1, Path path2) {
  final length = min(path1.length, path2.length);
  for (var i = 0; i < length; i++) {
    if (path1[i] < path2[i]) {
      return false;
    }
  }
  return true;
}

/// Returns true if path1 <= path2, otherwise returns false.
/// TODO: Rename this function.
bool pathLessOrEquals(Path path1, Path path2) {
  final length = min(path1.length, path2.length);
  for (var i = 0; i < length; i++) {
    if (path1[i] > path2[i]) {
      return false;
    }
  }
  return true;
}
