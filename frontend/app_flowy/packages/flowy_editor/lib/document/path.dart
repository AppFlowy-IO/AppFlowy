import 'dart:math';

import 'package:flutter/foundation.dart';

typedef Path = List<int>;

bool pathEquals(Path path1, Path path2) {
  return listEquals(path1, path2);
}
