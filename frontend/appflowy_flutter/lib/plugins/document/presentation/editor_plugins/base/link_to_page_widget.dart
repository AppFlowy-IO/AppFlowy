import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/insert_page_command.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void showLinkToPageMenu(
  OverlayState container,
  EditorState editorState,
  SelectionMenuService menuService,
  ViewLayoutPB pageType,
) {
  menuService.dismiss();

  final alignment = menuService.alignment;
  final offset = menuService.offset;
  final top = alignment == Alignment.bottomLeft ? offset.dy : null;
  final bottom = alignment == Alignment.topLeft ? offset.dy : null;

  keepEditorFocusNotifier.increase();
  late OverlayEntry linkToPageMenuEntry;
  linkToPageMenuEntry = FullScreenOverlayEntry(
    top: top,
    bottom: bottom,
    left: offset.dx,
    dismissCallback: () => keepEditorFocusNotifier.decrease(),
    builder: (context) => Material(
      color: Colors.transparent,
      child: LinkToPageMenu(
        editorState: editorState,
        layoutType: pageType,
        hintText: pageType.toHintText(),
        onSelected: (appPB, viewPB) async {
          try {
            await editorState.insertReferencePage(viewPB);
            linkToPageMenuEntry.remove();
          } on FlowyError catch (e) {
            Dialogs.show(
              child: FlowyErrorPage.message(
                e.msg,
                howToFix: LocaleKeys.errorDialog_howToFixFallback.tr(),
              ),
              context,
            );
          }
        },
      ),
    ),
  ).build();
  container.insert(linkToPageMenuEntry);
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
  final _focusNode = FocusNode(debugLabel: 'reference_list_widget');
  EditorStyle get style => widget.editorState.editorStyle;
  int _selectedIndex = 0;
  final int _totalItems = 0;
  Future<List<ViewPB>>? _availableLayout;
  final List<ViewPB> _items = [];

  Future<List<ViewPB>> fetchItems() async {
    final items =
        await ViewBackendService().fetchViewsWithLayoutType(widget.layoutType);
    _items
      ..clear()
      ..addAll(items);
    return items;
  }

  @override
  void initState() {
    _availableLayout = fetchItems();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    super.initState();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Focus(
      focusNode: _focusNode,
      onKey: _onKey,
      child: Container(
        width: 300,
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
        decoration: BoxDecoration(
          color: theme.cardColor,
          boxShadow: [
            BoxShadow(
              blurRadius: 5,
              spreadRadius: 1,
              color: Colors.black.withOpacity(0.1),
            ),
          ],
          borderRadius: BorderRadius.circular(6.0),
        ),
        child: _buildListWidget(
          context,
          _selectedIndex,
          _availableLayout,
        ),
      ),
    );
  }

  KeyEventResult _onKey(FocusNode node, RawKeyEvent event) {
    if (event is! RawKeyDownEvent ||
        _availableLayout == null ||
        _items.isEmpty) {
      return KeyEventResult.ignored;
    }

    final acceptedKeys = [
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.tab,
      LogicalKeyboardKey.enter
    ];

    if (!acceptedKeys.contains(event.logicalKey)) {
      return KeyEventResult.handled;
    }

    var newSelectedIndex = _selectedIndex;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown &&
        newSelectedIndex != _totalItems - 1) {
      newSelectedIndex += 1;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp &&
        newSelectedIndex != 0) {
      newSelectedIndex -= 1;
    } else if (event.logicalKey == LogicalKeyboardKey.tab) {
      newSelectedIndex += 1;
      newSelectedIndex %= _totalItems;
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      widget.onSelected(
        _items[_selectedIndex],
        _items[_selectedIndex],
      );
    }

    setState(() {
      _selectedIndex = newSelectedIndex;
    });

    return KeyEventResult.handled;
  }

  Widget _buildListWidget(
    BuildContext context,
    int selectedIndex,
    Future<List<ViewPB>>? items,
  ) {
    int index = 0;
    return FutureBuilder<List<ViewPB>>(
      builder: (context, snapshot) {
        if (snapshot.hasData &&
            snapshot.connectionState == ConnectionState.done) {
          final views = snapshot.data;
          final List<Widget> children = [
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
              children.add(
                FlowyButton(
                  isSelected: index == _selectedIndex,
                  leftIcon: FlowySvg(
                    view.iconData,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  text: FlowyText.regular(view.name),
                  onTap: () => widget.onSelected(view, view),
                ),
              );

              index += 1;
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
      future: items,
    );
  }
}

extension on ViewLayoutPB {
  String toHintText() {
    switch (this) {
      case ViewLayoutPB.Grid:
        return LocaleKeys.document_slashMenu_grid_selectAGridToLinkTo.tr();

      case ViewLayoutPB.Board:
        return LocaleKeys.document_slashMenu_board_selectABoardToLinkTo.tr();

      case ViewLayoutPB.Calendar:
        return LocaleKeys.document_slashMenu_calendar_selectACalendarToLinkTo
            .tr();

      default:
        throw Exception('Unknown layout type');
    }
  }
}
