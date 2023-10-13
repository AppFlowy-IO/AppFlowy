part of 'panes_cubit.dart';

class PanesState extends Equatable {
  final PaneNode root;
  final int count;
  final PaneNode activePane;
  final PaneNode firstLeafNode;
  final bool allowPaneDrag;

  const PanesState({
    required this.activePane,
    required this.root,
    required this.count,
    required this.allowPaneDrag,
    required this.firstLeafNode,
  });

  factory PanesState.initial() {
    final pane = PaneNode.initial();
    return PanesState(
      activePane: pane,
      root: pane,
      count: 1,
      allowPaneDrag: false,
      firstLeafNode: pane,
    );
  }

  PanesState copyWith({
    PaneNode? activePane,
    bool? allowPaneDrag,
    PaneNode? root,
    int? count,
    PaneNode? firstLeafNode,
  }) {
    return PanesState(
      root: root ?? this.root,
      activePane: activePane ?? this.activePane,
      count: count ?? this.count,
      allowPaneDrag: allowPaneDrag ?? this.allowPaneDrag,
      firstLeafNode: firstLeafNode ?? this.firstLeafNode,
    );
  }

  @override
  List<Object?> get props =>
      [root, count, activePane, allowPaneDrag, firstLeafNode];
}
