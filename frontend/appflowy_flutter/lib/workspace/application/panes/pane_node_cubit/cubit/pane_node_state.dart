part of 'pane_node_cubit.dart';

class PaneNodeState extends Equatable {
  final List<double> flex;
  final List<double> resizeOffset;
  final List<double> resizeStart;

  const PaneNodeState({
    required this.flex,
    required this.resizeStart,
    required this.resizeOffset,
  });

  factory PaneNodeState.initial({
    required int length,
    required double size,
  }) {
    final flex = List.generate(length, (_) => 1 / length);
    final initialOffset = [flex[0]];

    for (int i = 1; i < length; i++) {
      initialOffset.add((size * flex[i]) + initialOffset[i - 1]);
    }
    return PaneNodeState(
      flex: flex,
      resizeStart: List.generate(length, (_) => 0),
      resizeOffset: initialOffset,
    );
  }

  PaneNodeState copyWith({
    List<double>? flex,
    List<double>? resizeOffset,
    List<double>? resizeStart,
  }) {
    return PaneNodeState(
      flex: flex ?? this.flex,
      resizeOffset: resizeOffset ?? this.resizeOffset,
      resizeStart: resizeStart ?? this.resizeStart,
    );
  }

  @override
  List<Object?> get props => [...flex];
}
