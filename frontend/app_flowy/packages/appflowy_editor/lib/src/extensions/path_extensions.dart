import 'package:appflowy_editor/src/document/path.dart';

import 'dart:math';

extension PathExtensions on Path {
  bool operator >=(Path other) {
    if (pathEquals(this, other)) {
      return true;
    }
    return this > other;
  }

  bool operator >(Path other) {
    if (pathEquals(this, other)) {
      return false;
    }
    final length = min(this.length, other.length);
    for (var i = 0; i < length; i++) {
      if (this[i] < other[i]) {
        return false;
      } else if (this[i] > other[i]) {
        return true;
      }
    }
    if (this.length < other.length) {
      return false;
    }
    return true;
  }

  bool operator <=(Path other) {
    if (pathEquals(this, other)) {
      return true;
    }
    return this < other;
  }

  bool operator <(Path other) {
    if (pathEquals(this, other)) {
      return false;
    }
    final length = min(this.length, other.length);
    for (var i = 0; i < length; i++) {
      if (this[i] > other[i]) {
        return false;
      } else if (this[i] < other[i]) {
        return true;
      }
    }
    if (this.length > other.length) {
      return false;
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
