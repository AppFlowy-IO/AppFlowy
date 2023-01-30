import 'package:app_flowy/plugins/document/presentation/plugins/base/insert_page_command.dart';
import 'package:app_flowy/plugins/grid/presentation/grid_page.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/app/app_service.dart';
import 'package:app_flowy/workspace/application/view/view_ext.dart';
import 'package:app_flowy/workspace/presentation/home/home_stack.dart';
import 'package:app_flowy/workspace/presentation/home/menu/menu.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pbserver.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flutter/material.dart';

const String kGridType = 'grid';

class GridNodeWidgetBuilder extends NodeWidgetBuilder<Node> {
  @override
  Widget build(NodeWidgetContext<Node> context) {
    return _GridWidget(
      key: context.node.key,
      node: context.node,
      editorState: context.editorState,
    );
  }

  @override
  NodeValidator<Node> get nodeValidator => (node) {
        return node.attributes[kAppID] is String &&
            node.attributes[kViewID] is String;
      };
}

class _GridWidget extends StatefulWidget {
  const _GridWidget({
    Key? key,
    required this.node,
    required this.editorState,
  }) : super(key: key);

  final Node node;
  final EditorState editorState;

  @override
  State<_GridWidget> createState() => _GridWidgetState();
}

class _GridWidgetState extends State<_GridWidget> with SelectableMixin {
  RenderBox get _renderBox => context.findRenderObject() as RenderBox;

  String get gridID {
    return widget.node.attributes[kViewID];
  }

  String get appID {
    return widget.node.attributes[kAppID];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dartz.Either<ViewPB, FlowyError>>(
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final board = snapshot.data?.getLeftOrNull<ViewPB>();
          if (board != null) {
            return _buildGrid(context, board);
          }
        }
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
      future: AppService().getView(appID, gridID),
    );
  }

  Widget _buildGrid(BuildContext context, ViewPB viewPB) {
    return MouseRegion(
      onHover: (event) {
        if (widget.node.isSelected(widget.editorState)) {
          widget.editorState.service.scrollService?.disable();
        }
      },
      onExit: (event) {
        widget.editorState.service.scrollService?.enable();
      },
      child: SizedBox(
        height: 400,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 20,
              child: FlowyTextButton(
                viewPB.name,
                onPressed: () {
                  getIt<MenuSharedState>().latestOpenView = viewPB;
                  getIt<HomeStackManager>().setPlugin(viewPB.plugin());
                },
              ),
            ),
            GridPage(
              key: ValueKey(viewPB.id),
              view: viewPB,
              onEditStateChanged: () {
                /// Clear selection when the edit state changes, otherwise the editor will prevent the keyboard event when the board is in edit mode.
                widget.editorState.service.selectionService.clearSelection();
              },
            ),
          ],
        ),
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
    return Position(path: widget.node.path, offset: 0);
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
      endOffset: 0,
    );
  }

  @override
  Offset localToGlobal(Offset offset) {
    return _renderBox.localToGlobal(offset);
  }
}
