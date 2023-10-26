part of 'pane_node_bloc.dart';

@freezed
class PaneNodeState with _$PaneNodeState {
  const factory PaneNodeState({
    required List<double> flex,
  }) = _PaneNodeState;

  factory PaneNodeState.initial({
    required int length,
    required double size,
  }) {
    final flex = List.generate(length, (_) => 1 / length);
    return PaneNodeState(
      flex: flex,
    );
  }
}
