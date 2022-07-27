import 'package:flutter/material.dart';

import './path.dart';

class Position {
  final Path path;
  final int offset;

  Position({
    required this.path,
    this.offset = 0,
  });

  @override
  bool operator ==(Object other) {
    if (other is! Position) {
      return false;
    }
    return pathEquals(path, other.path) && offset == other.offset;
  }

  @override
  int get hashCode {
    final pathHash = hashList(path);
    return Object.hash(pathHash, offset);
  }

  Position copyWith({Path? path, int? offset}) {
    return Position(
      path: path ?? this.path,
      offset: offset ?? this.offset,
    );
  }

  @override
  String toString() => 'path = $path, offset = $offset';
}
