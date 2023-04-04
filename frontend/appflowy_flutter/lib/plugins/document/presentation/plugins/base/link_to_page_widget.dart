import 'package:appflowy/workspace/application/app/app_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'insert_page_command.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';

EditorState? _editorState;
OverlayEntry? _linkToPageMenu;

void showLinkToPageMenu(
  EditorState editorState,
  SelectionMenuService menuService,
  BuildContext context,
  ViewLayoutPB pageType,
) {
  final alignment = menuService.alignment;
  final offset = menuService.offset;
  menuService.dismiss();

  _editorState = editorState;

  String hintText = '';
  switch (pageType) {
    case ViewLayoutPB.Grid:
      hintText = LocaleKeys.document_slashMenu_grid_selectAGridToLinkTo.tr();
      break;
    case ViewLayoutPB.Board:
      hintText = LocaleKeys.document_slashMenu_board_selectABoardToLinkTo.tr();
      break;
    default:
      throw Exception('Unknown layout type');
  }

  _linkToPageMenu?.remove();
  _linkToPageMenu = OverlayEntry(builder: (context) {
    return Positioned(
      top: alignment == Alignment.bottomLeft ? offset.dy : null,
      bottom: alignment == Alignment.topLeft ? offset.dy : null,
      left: offset.dx,
      child: Material(
        color: Colors.transparent,
        child: LinkToPageMenu(
          editorState: editorState,
          layoutType: pageType,
          hintText: hintText,
          onSelected: (viewPB, childViewPB) {
            editorState.insertPage(viewPB, childViewPB);
          },
        ),
      ),
    );
  });

  Overlay.of(context)?.insert(_linkToPageMenu!);

  editorState.service.selectionService.currentSelection
      .addListener(dismissLinkToPageMenu);
}

void dismissLinkToPageMenu() {
  _linkToPageMenu?.remove();
  _linkToPageMenu = null;

  _editorState?.service.selectionService.currentSelection
      .removeListener(dismissLinkToPageMenu);
  _editorState = null;
}

class LinkToPageMenu extends StatefulWidget {
  const LinkToPageMenu({
    super.key,
    required this.editorState,
    required this.layoutType,
    required this.hintText,
    required this.onSelected,
  });

  final EditorState editorState;
  final ViewLayoutPB layoutType;
  final String hintText;
  final void Function(ViewPB view, ViewPB childView) onSelected;

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
        child: _buildListWidget(context),
      ),
    );
  }

  Widget _buildListWidget(BuildContext context) {
    return FutureBuilder<List<dartz.Tuple2<ViewPB, List<ViewPB>>>>(
      builder: (context, snapshot) {
        if (snapshot.hasData &&
            snapshot.connectionState == ConnectionState.done) {
          final views = snapshot.data;
          final children = <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: FlowyText.regular(
                widget.hintText,
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ];
          if (views != null && views.isNotEmpty) {
            for (final view in views) {
              if (view.value2.isNotEmpty) {
                children.add(
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: FlowyText.regular(
                      view.value1.name,
                    ),
                  ),
                );
                for (final value in view.value2) {
                  children.add(
                    FlowyButton(
                      leftIcon: svgWidget(
                        _iconName(value),
                        color: Theme.of(context).iconTheme.color,
                      ),
                      text: FlowyText.regular(value.name),
                      onTap: () => widget.onSelected(view.value1, value),
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
      future: AppBackendService().fetchViews(widget.layoutType),
    );
  }

  String _iconName(ViewPB viewPB) {
    switch (viewPB.layout) {
      case ViewLayoutPB.Grid:
        return 'editor/grid';
      case ViewLayoutPB.Board:
        return 'editor/board';
      default:
        throw Exception('Unknown layout type');
    }
  }
}
