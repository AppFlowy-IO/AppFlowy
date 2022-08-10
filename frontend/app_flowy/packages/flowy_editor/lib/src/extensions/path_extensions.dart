import 'package:flowy_editor/src/document/path.dart';

import 'dart:math';

extension PathExtensions on Path {
  bool operator >=(Path other) {
    final length = min(this.length, other.length);
    for (var i = 0; i < length; i++) {
      if (this[i] < other[i]) {
        return false;
      }
    }
    return true;
  }

  bool operator <=(Path other) {
    final length = min(this.length, other.length);
    for (var i = 0; i < length; i++) {
      if (this[i] > other[i]) {
        return false;
      }
    }
    return true;
  }

  Path get next {
    Path nextPath = Path.from(this, growable: true);
    if (isEmpty) {
      return nextPath;
    }
    final last = nextPath.last;
    return nextPath
      ..removeLast()
      ..add(last + 1);
  }
}
