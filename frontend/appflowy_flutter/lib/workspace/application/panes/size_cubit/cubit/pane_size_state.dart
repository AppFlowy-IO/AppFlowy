part of 'pane_size_cubit.dart';

@immutable
class PaneSizeState extends Equatable {
  final double resizeOffset;
  final double resizeStart;

  const PaneSizeState({
    required this.resizeOffset,
    required this.resizeStart,
  });

  factory PaneSizeState.initial({required double offset}) => PaneSizeState(
        resizeOffset: offset,
        resizeStart: 0,
      );

  PaneSizeState copyWith({
    double? resizeOffset,
    double? resizeStart,
  }) {
    return PaneSizeState(
      resizeOffset: resizeOffset ?? this.resizeOffset,
      resizeStart: resizeStart ?? this.resizeStart,
    );
  }

  @override
  List<Object?> get props => [resizeOffset, resizeStart];
}
