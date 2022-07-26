import 'package:flowy_editor/document/path.dart';
import 'package:flowy_editor/document/position.dart';

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

  bool isCollapsed() {
    return start == end;
  }

  Selection copyWith({Position? start, Position? end}) {
    return Selection(
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }
}
