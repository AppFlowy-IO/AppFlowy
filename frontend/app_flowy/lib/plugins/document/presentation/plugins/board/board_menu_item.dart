import 'package:app_flowy/plugins/document/presentation/plugins/board/board_node_widget.dart';
import 'package:app_flowy/workspace/application/app/app_service.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/app.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter/material.dart';

SelectionMenuItem boardMenuItem = SelectionMenuItem(
  name: () => 'Board',
  icon: (editorState, onSelected) => Icon(
    Icons.emoji_emotions_outlined,
    color: onSelected
        ? editorState.editorStyle.selectionMenuItemSelectedIconColor
        : editorState.editorStyle.selectionMenuItemIconColor,
    size: 18.0,
  ),
  keywords: ['board'],
  handler: _showLinkToPageMenu,
);

EditorState? _editorState;
OverlayEntry? _linkToPageMenu;
void _showLinkToPageMenu(
  EditorState editorState,
  SelectionMenuService menuService,
  BuildContext context,
) {
  final aligment = menuService.alignment;
  final offset = menuService.offset;
  menuService.dismiss();

  _editorState = editorState;

  _linkToPageMenu?.remove();
  _linkToPageMenu = OverlayEntry(builder: (context) {
    return Positioned(
      top: aligment == Alignment.bottomLeft ? offset.dy : null,
      bottom: aligment == Alignment.topLeft ? offset.dy : null,
      left: offset.dx,
      child: Material(
        color: Colors.transparent,
        child: LinkToPageMenu(
          editorState: editorState,
        ),
      ),
    );
  });

  Overlay.of(context)?.insert(_linkToPageMenu!);

  editorState.service.selectionService.currentSelection
      .addListener(_dismissLinkToPageMenu);
}

void _dismissLinkToPageMenu() {
  _linkToPageMenu?.remove();
  _linkToPageMenu = null;

  _editorState?.service.selectionService.currentSelection
      .removeListener(_dismissLinkToPageMenu);
  _editorState = null;
}

class LinkToPageMenu extends StatefulWidget {
  const LinkToPageMenu({
    super.key,
    required this.editorState,
  });

  final EditorState editorState;

  @override
  State<LinkToPageMenu> createState() => _LinkToPageMenuState();
}

class _LinkToPageMenuState extends State<LinkToPageMenu> {
  EditorStyle get style => widget.editorState.editorStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      width: 300,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
        decoration: BoxDecoration(
          color: style.selectionMenuBackgroundColor,
          boxShadow: [
            BoxShadow(
              blurRadius: 5,
              spreadRadius: 1,
              color: Colors.black.withOpacity(0.1),
            ),
          ],
          borderRadius: BorderRadius.circular(6.0),
        ),
        child: _buildBoardListWidget(context),
      ),
    );
  }

  Widget _buildBoardListWidget(BuildContext context) {
    return FutureBuilder<List<dartz.Tuple2<AppPB, List<ViewPB>>>>(
      builder: (context, snapshot) {
        if (snapshot.hasData &&
            snapshot.connectionState == ConnectionState.done) {
          final apps = snapshot.data;
          final children = <Widget>[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: FlowyText.regular(
                'Select a board to link to',
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ];
          if (apps != null && apps.isNotEmpty) {
            for (final app in apps) {
              if (app.value2.isNotEmpty) {
                children.add(
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: FlowyText.regular(
                      app.value1.name,
                    ),
                  ),
                );
                for (final board in app.value2) {
                  children.add(
                    FlowyButton(
                      leftIcon: svgWidget(
                        'file_icon',
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      text: FlowyText.regular(board.name),
                      onTap: () => widget.editorState.insertBoard(
                        app.value1,
                        board,
                      ),
                    ),
                  );
                }
              }
            }
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
      future: fetchBoards(),
    );
  }

  Future<List<dartz.Tuple2<AppPB, List<ViewPB>>>> fetchBoards() async {
    return AppService().fetchViews(ViewLayoutTypePB.Board);
  }
}

extension on EditorState {
  void insertBoard(AppPB appPB, ViewPB viewPB) {
    final selection = service.selectionService.currentSelection.value;
    final textNodes =
        service.selectionService.currentSelectedNodes.whereType<TextNode>();
    if (selection == null || textNodes.isEmpty) {
      return;
    }
    final transaction = this.transaction;
    transaction.insertNode(
      selection.end.path,
      Node(
        type: kBoardType,
        attributes: {
          kAppID: appPB.id,
          kBoardID: viewPB.id,
        },
      ),
    );
    transaction.afterSelection = selection;
    apply(transaction);
  }
}
