import 'package:appflowy_editor/src/core/document/path.dart';

class Position {
  final Path path;
  final int offset;

  Position({
    required this.path,
    this.offset = 0,
  });

  factory Position.fromJson(Map<String, dynamic> json) {
    final path = Path.from(json['path'] as List);
    final offset = json['offset'];
    return Position(
      path: path,
      offset: offset ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Position &&
        other.path.equals(path) &&
        other.offset == offset;
  }

  @override
  int get hashCode => Object.hash(offset, Object.hashAll(path));

  @override
  String toString() => 'path = $path, offset = $offset';

  Position copyWith({Path? path, int? offset}) {
    return Position(
      path: path ?? this.path,
      offset: offset ?? this.offset,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'offset': offset,
    };
  }
}
