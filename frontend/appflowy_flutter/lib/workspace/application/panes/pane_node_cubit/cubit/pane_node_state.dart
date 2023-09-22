part of 'pane_node_cubit.dart';

class PaneNodeState extends Equatable {
  final List<double> flex;
  const PaneNodeState({required this.flex});

  factory PaneNodeState.initial({required int length}) => PaneNodeState(
        flex: List.generate(
          length,
          (_) => 1 / length,
        ),
      );

  PaneNodeState copyWith({
    List<double>? flex,
    double? totalOffset,
  }) {
    return PaneNodeState(
      flex: flex ?? this.flex,
    );
  }

  @override
  List<Object?> get props => [...flex];
}
