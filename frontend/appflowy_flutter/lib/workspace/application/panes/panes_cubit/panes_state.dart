part of 'panes_cubit.dart';

class PanesState extends Equatable {
  final PaneNode root;
  final int count;
  final PaneNode activePane;
  final Offset dragOffset;

  const PanesState({
    required this.activePane,
    required this.root,
    required this.count,
    required this.dragOffset,
  });

  factory PanesState.initial() {
    final pane = PaneNode(
      tabs: Tabs(),
      children: const [],
      paneId: nanoid(),
      axis: null,
    );
    return PanesState(
      activePane: pane,
      root: pane,
      count: 1,
      dragOffset: const Offset(0, 0),
    );
  }

  PanesState copyWith({
    PaneNode? activePane,
    bool? allowPaneDrag,
    PaneNode? root,
    int? count,
    Offset? dragOffset,
  }) {
    return PanesState(
      root: root ?? this.root,
      activePane: activePane ?? this.activePane,
      count: count ?? this.count,
      dragOffset: dragOffset ?? this.dragOffset,
    );
  }

  @override
  List<Object?> get props => [root, count, activePane, dragOffset];
}
