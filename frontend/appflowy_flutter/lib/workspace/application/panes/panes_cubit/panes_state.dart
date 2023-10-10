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
      tabs: TabsController(),
      children: const [],
      paneId: nanoid(),
      axis: null,
    );
    return PanesState(
      activePane: pane,
      root: pane,
      count: 1,
      allowPaneDrag: false,
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
      activePane: activePane ?? this.activePane,
      count: count ?? this.count,
      allowPaneDrag: allowPaneDrag ?? this.allowPaneDrag,
    );
  }

  @override
  List<Object?> get props => [root, count, activePane, allowPaneDrag];
}
