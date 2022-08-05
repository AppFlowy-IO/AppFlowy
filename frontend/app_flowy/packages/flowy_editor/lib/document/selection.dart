import 'package:flowy_editor/document/path.dart';
import 'package:flowy_editor/document/position.dart';
import 'package:flowy_editor/extensions/path_extensions.dart';

class Selection {
  final Position start;
  final Position end;

  Selection({
    required this.start,
    required this.end,
  });

  Selection.single({
    required Path path,
    required int startOffset,
    int? endOffset,
  })  : start = Position(path: path, offset: startOffset),
        end = Position(path: path, offset: endOffset ?? startOffset);

  Selection.collapsed(Position position)
      : start = position,
        end = position;

  Selection collapse({bool atStart = false}) {
    if (atStart) {
      return Selection(start: start, end: start);
    } else {
      return Selection(start: end, end: end);
    }
  }

  bool get isCollapsed => start == end;
  bool get isSingle => pathEquals(start.path, end.path);
  bool get isUpward =>
      start.path >= end.path && !pathEquals(start.path, end.path);
  bool get isDownward =>
      start.path <= end.path && !pathEquals(start.path, end.path);

  Selection copyWith({Position? start, Position? end}) {
    return Selection(
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }

  Selection copy() => Selection(start: start, end: end);

  @override
  String toString() => '[Selection] start = $start, end = $end';

  Map<String, dynamic> toJson() {
    return {
      "start": start.toJson(),
      "end": end.toJson(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (other is! Selection) {
      return false;
    }
    if (identical(this, other)) {
      return true;
    }
    return start == other.start && end == other.end;
  }

  @override
  int get hashCode => Object.hash(start, end);
}
