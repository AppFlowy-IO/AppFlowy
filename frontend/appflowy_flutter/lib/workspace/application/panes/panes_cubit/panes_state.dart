part of 'panes_cubit.dart';

class PanesState extends Equatable {
  final PaneNode root;
  final int count;
  final PaneNode activePane;

  const PanesState({
    required this.activePane,
    required this.root,
    required this.count,
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
    );
  }

  PanesState copyWith({
    PaneNode? activePane,
    PaneNode? root,
    int? count,
  }) {
    return PanesState(
      root: root ?? this.root,
      activePane: activePane ?? this.activePane,
      count: count ?? this.count,
    );
  }

  @override
  List<Object?> get props => [root, count, activePane];
}
