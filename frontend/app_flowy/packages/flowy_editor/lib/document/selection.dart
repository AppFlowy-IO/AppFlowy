import './position.dart';

class Selection {
  final Position start;
  final Position end;

  Selection({
    required this.start,
    required this.end,
  });

  factory Selection.collapsed(Position pos) {
    return Selection(start: pos, end: pos);
  }

  Selection collapse({ bool atStart = false }) {
    if (atStart) {
      return Selection(start: start, end: start);
    } else {
      return Selection(start: end, end: end);
    }
  }

  bool isCollapsed() {
    return start == end;
  }

}
