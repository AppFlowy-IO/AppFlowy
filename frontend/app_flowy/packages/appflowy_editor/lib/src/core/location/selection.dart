import 'package:appflowy_editor/src/core/document/path.dart';
import 'package:appflowy_editor/src/core/location/position.dart';

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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Selection && other.start == start && other.end == end;
  }

  @override
  int get hashCode => start.hashCode ^ end.hashCode;

  @override
  String toString() => 'start = $start, end = $end';

  /// Returns a Boolean indicating whether the selection's start and end points
  /// are at the same position.
  bool get isCollapsed => start == end;

  /// Returns a Boolean indicating whether the selection's start and end points
  /// are at the same path.
  bool get isSingle => start.path.equals(end.path);

  /// Returns a Boolean indicating whether the selection is forward.
  bool get isForward =>
      (start.path > end.path) || (isSingle && start.offset > end.offset);

  /// Returns a Boolean indicating whether the selection is backward.
  bool get isBackward =>
      (start.path < end.path) || (isSingle && start.offset < end.offset);

  /// Returns a normalized selection that direction is forward.
  Selection get normalized => isBackward ? copyWith() : reversed.copyWith();

  /// Returns a reversed selection.
  Selection get reversed => copyWith(start: end, end: start);

  /// Returns the offset in the starting position under the normalized selection.
  int get startIndex => normalized.start.offset;

  /// Returns the offset in the ending position under the normalized selection.
  int get endIndex => normalized.end.offset;

  int get length => endIndex - startIndex;

  /// Collapses the current selection to a single point.
  ///
  /// If [atStart] is true, the selection will be collapsed to the start point.
  /// If [atStart] is false, the selection will be collapsed to the end point.
  Selection collapse({bool atStart = false}) {
    if (atStart) {
      return copyWith(end: start);
    } else {
      return copyWith(start: end);
    }
  }

  Selection copyWith({Position? start, Position? end}) {
    return Selection(
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start': start.toJson(),
      'end': end.toJson(),
    };
  }
}
