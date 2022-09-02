import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:pod_player/pod_player.dart';

class YouTubeLinkNodeBuilder extends NodeWidgetBuilder<Node> {
  @override
  Widget build(NodeWidgetContext<Node> context) {
    return LinkNodeWidget(
      key: context.node.key,
      node: context.node,
      editorState: context.editorState,
    );
  }

  @override
  NodeValidator<Node> get nodeValidator => ((node) {
        return node.type == 'youtube_link';
      });
}

class LinkNodeWidget extends StatefulWidget {
  final Node node;
  final EditorState editorState;

  const LinkNodeWidget({
    Key? key,
    required this.node,
    required this.editorState,
  }) : super(key: key);

  @override
  State<LinkNodeWidget> createState() => _YouTubeLinkNodeWidgetState();
}

class _YouTubeLinkNodeWidgetState extends State<LinkNodeWidget>
    with SelectableMixin {
  Node get node => widget.node;
  EditorState get editorState => widget.editorState;
  String get src => widget.node.attributes['youtube_link'] as String;

  @override
  Position end() {
    // TODO: implement end
    throw UnimplementedError();
  }

  @override
  Position start() {
    // TODO: implement start
    throw UnimplementedError();
  }

  @override
  List<Rect> getRectsInSelection(Selection selection) {
    // TODO: implement getRectsInSelection
    throw UnimplementedError();
  }

  @override
  Selection getSelectionInRange(Offset start, Offset end) {
    // TODO: implement getSelectionInRange
    throw UnimplementedError();
  }

  @override
  Offset localToGlobal(Offset offset) {
    throw UnimplementedError();
  }

  @override
  Position getPositionInOffset(Offset start) {
    // TODO: implement getPositionInOffset
    throw UnimplementedError();
  }

  @override
  Widget build(BuildContext context) {
    return _build(context);
  }

  late final PodPlayerController controller;

  @override
  void initState() {
    controller = PodPlayerController(
      playVideoFrom: PlayVideoFrom.network(
        src,
      ),
    )..initialise();
    super.initState();
  }

  Widget _build(BuildContext context) {
    return Column(
      children: [
        PodVideoPlayer(controller: controller),
      ],
    );
  }
}
