part of 'panes_cubit.dart';

class PanesState extends Equatable {
  final PaneNode root;
  final int count;
  final PaneNode activePane;
  final bool allowPaneDrag;

  const PanesState({
    required this.activePane,
    required this.root,
    required this.count,
    required this.allowPaneDrag,
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
      allowPaneDrag: false,
      root: pane,
      count: 1,
    );
  }

  PanesState copyWith({
    PaneNode? activePane,
    bool? allowPaneDrag,
    PaneNode? root,
    int? count,
  }) {
    return PanesState(
      root: root ?? this.root,
      allowPaneDrag: allowPaneDrag ?? this.allowPaneDrag,
      activePane: activePane ?? this.activePane,
      count: count ?? this.count,
    );
  }

  @override
  List<Object?> get props => [root, count, activePane, allowPaneDrag];
}
