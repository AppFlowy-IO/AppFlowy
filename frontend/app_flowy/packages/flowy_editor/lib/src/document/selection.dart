import 'package:flowy_editor/src/document/path.dart';
import 'package:flowy_editor/src/document/position.dart';
import 'package:flowy_editor/src/extensions/path_extensions.dart';

/// Selection represents the selected area or the cursor area in the editor.
///
/// [Selection] is directional.
///
/// 1. forward，the end position is before the start position.
/// 2. backward, the end position is after the start position.
/// 3. collapsed, the end position is equal to the start position.
class Selection {
  /// Create a selection with [start], [end].
  Selection({
    required this.start,
    required this.end,
  });

  /// Create a selection with [Path], [startOffset] and [endOffset].
  ///
  /// The [endOffset] is optional.
  ///
  /// This constructor will return a collapsed [Selection] if [endOffset] is null.
  ///
  Selection.single({
    required Path path,
    required int startOffset,
    int? endOffset,
  })  : start = Position(path: path, offset: startOffset),
        end = Position(path: path, offset: endOffset ?? startOffset);

  /// Create a collapsed selection with [position].
  Selection.collapsed(Position position)
      : start = position,
        end = position;

  final Position start;
  final Position end;

  bool get isCollapsed => start == end;
  bool get isSingle => pathEquals(start.path, end.path);
  bool get isForward =>
      (start.path >= end.path && !pathEquals(start.path, end.path)) ||
      (isSingle && start.offset > end.offset);
  bool get isBackward =>
      (start.path <= end.path && !pathEquals(start.path, end.path)) ||
      (isSingle && start.offset < end.offset);

  Selection get reversed => copyWith(start: end, end: start);

  Selection collapse({bool atStart = false}) {
    if (atStart) {
      return Selection(start: start, end: start);
    } else {
      return Selection(start: end, end: end);
    }
  }

  Selection copyWith({Position? start, Position? end}) {
    return Selection(
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }

  Selection copy() => Selection(start: start, end: end);

  Map<String, dynamic> toJson() {
    return {
      'start': start.toJson(),
      'end': end.toJson(),
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

  @override
  String toString() => '[Selection] start = $start, end = $end';
}
