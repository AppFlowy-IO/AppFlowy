import 'package:appflowy_editor/src/core/document/path.dart';

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
    return path.equals(other.path) && offset == other.offset;
  }

  @override
  int get hashCode {
    final pathHash = Object.hashAll(path);
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

  Map<String, dynamic> toJson() {
    return {
      "path": path.toList(),
      "offset": offset,
    };
  }
}
