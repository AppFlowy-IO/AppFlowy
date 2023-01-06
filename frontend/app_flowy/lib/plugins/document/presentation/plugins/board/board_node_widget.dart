import 'package:app_flowy/plugins/board/presentation/board_page.dart';
import 'package:app_flowy/workspace/application/app/app_service.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:flowy_sdk/protobuf/flowy-error/errors.pbserver.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter/material.dart';

const String kBoardType = 'board';
const String kAppID = 'app_id';
const String kBoardID = 'board_id';

class BoardNodeWidgetBuilder extends NodeWidgetBuilder<Node> {
  @override
  Widget build(NodeWidgetContext<Node> context) {
    return _BoardWidget(
      key: context.node.key,
      node: context.node,
      editorState: context.editorState,
    );
  }

  @override
  NodeValidator<Node> get nodeValidator => (node) {
        return node.attributes[kBoardID] is String &&
            node.attributes[kAppID] is String;
      };
}

class _BoardWidget extends StatefulWidget {
  const _BoardWidget({
    Key? key,
    required this.node,
    required this.editorState,
  }) : super(key: key);

  final Node node;
  final EditorState editorState;

  @override
  State<_BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<_BoardWidget> with SelectableMixin {
  RenderBox get _renderBox => context.findRenderObject() as RenderBox;

  String get boardID {
    return widget.node.attributes[kBoardID];
  }

  String get appID {
    return widget.node.attributes[kAppID];
  }

  late Future<dartz.Either<ViewPB, FlowyError>> board;

  @override
  void initState() {
    super.initState();

    board = fetchBoard();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dartz.Either<ViewPB, FlowyError>>(
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final board = snapshot.data?.getLeftOrNull<ViewPB>();
          if (board != null) {
            return _buildBoard(context, board);
          }
        }
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
      future: board,
    );
  }

  Future<dartz.Either<ViewPB, FlowyError>> fetchBoard() async {
    return AppService().getView(appID, boardID);
  }

  Widget _buildBoard(BuildContext context, ViewPB viewPB) {
    return MouseRegion(
      onEnter: (event) {
        widget.editorState.service.scrollService?.disable();
      },
      onExit: (event) {
        widget.editorState.service.scrollService?.enable();
      },
      child: SizedBox(
        height: 400,
        child: BoardPage(key: ValueKey(viewPB.id), view: viewPB),
      ),
    );
  }

  @override
  bool get shouldCursorBlink => false;

  @override
  CursorStyle get cursorStyle => CursorStyle.borderLine;

  @override
  Position start() {
    return Position(path: widget.node.path, offset: 0);
  }

  @override
  Position end() {
    return Position(path: widget.node.path, offset: 1);
  }

  @override
  Position getPositionInOffset(Offset start) {
    return end();
  }

  @override
  List<Rect> getRectsInSelection(Selection selection) {
    return [Offset.zero & _renderBox.size];
  }

  @override
  Rect? getCursorRectInPosition(Position position) {
    final size = _renderBox.size;
    return Rect.fromLTWH(-size.width / 2.0, 0, size.width, size.height);
  }

  @override
  Selection getSelectionInRange(Offset start, Offset end) {
    return Selection.single(
      path: widget.node.path,
      startOffset: 0,
      endOffset: 1,
    );
  }

  @override
  Offset localToGlobal(Offset offset) {
    return _renderBox.localToGlobal(offset);
  }
}
