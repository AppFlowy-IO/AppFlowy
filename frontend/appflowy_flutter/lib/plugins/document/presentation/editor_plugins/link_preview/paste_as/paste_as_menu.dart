import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/link_embed/link_embed_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/link_preview/shared.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/menu/menu_extension.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _menuHeighgt = 188.0, _menuWidth = 288.0;

class PasteAsMenuService {
  PasteAsMenuService({
    required this.context,
    required this.editorState,
  });

  final BuildContext context;
  final EditorState editorState;
  OverlayEntry? _menuEntry;

  void show(String href) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _show(href));
  }

  void dismiss() {
    if (_menuEntry != null) {
      keepEditorFocusNotifier.decrease();
      // editorState.service.scrollService?.enable();
      // editorState.service.keyboardService?.enable();
    }
    _menuEntry?.remove();
    _menuEntry = null;
  }

  void _show(String href) {
    final Size editorSize = editorState.renderBox?.size ?? Size.zero;
    if (editorSize == Size.zero) return;
    final menuPosition = editorState.calculateMenuOffset(
      menuWidth: _menuWidth,
      menuHeight: _menuHeighgt,
    );
    if (menuPosition == null) return;
    final ltrb = menuPosition.ltrb;

    _menuEntry = OverlayEntry(
      builder: (context) => SizedBox(
        height: editorSize.height,
        width: editorSize.width,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: dismiss,
          child: Stack(
            children: [
              ltrb.buildPositioned(
                child: PasteAsMenu(
                  editorState: editorState,
                  onSelect: (t) {
                    final selection = editorState.selection;
                    if (selection == null) return;
                    final end = selection.end;
                    final urlSelection = Selection(
                      start: end.copyWith(offset: end.offset - href.length),
                      end: end,
                    );
                    if (t == PasteMenuType.bookmark) {
                      convertUrlToLinkPreview(editorState, urlSelection, href);
                    } else if (t == PasteMenuType.mention) {
                      convertUrlToMention(editorState, urlSelection);
                    } else if (t == PasteMenuType.embed) {
                      convertUrlToLinkPreview(
                        editorState,
                        urlSelection,
                        href,
                        previewType: LinkEmbedKeys.embed,
                      );
                    }
                    dismiss();
                  },
                  onDismiss: dismiss,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_menuEntry!);

    keepEditorFocusNotifier.increase();
    // editorState.service.keyboardService?.disable(showCursor: true);
    // editorState.service.scrollService?.disable();
  }
}

class PasteAsMenu extends StatefulWidget {
  const PasteAsMenu({
    super.key,
    required this.onSelect,
    required this.onDismiss,
    required this.editorState,
  });
  final ValueChanged<PasteMenuType?> onSelect;
  final VoidCallback onDismiss;
  final EditorState editorState;

  @override
  State<PasteAsMenu> createState() => _PasteAsMenuState();
}

class _PasteAsMenuState extends State<PasteAsMenu> {
  final focusNode = FocusNode(debugLabel: 'paste_as_menu');
  final ValueNotifier<int> selectedIndexNotifier = ValueNotifier(0);

  EditorState get editorState => widget.editorState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => focusNode.requestFocus(),
    );
    editorState.selectionNotifier.addListener(dismiss);
  }

  @override
  void dispose() {
    focusNode.dispose();
    selectedIndexNotifier.dispose();
    editorState.selectionNotifier.removeListener(dismiss);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Focus(
      focusNode: focusNode,
      onKeyEvent: onKeyEvent,
      child: Container(
        width: _menuWidth,
        height: _menuHeighgt,
        padding: EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: theme.surfaceColorScheme.primary,
          boxShadow: [theme.shadow.medium],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 32,
              padding: EdgeInsets.all(8),
              child: FlowyText.semibold(
                color: theme.textColorScheme.primary,
                LocaleKeys.document_plugins_linkPreview_typeSelection_pasteAs
                    .tr(),
              ),
            ),
            ...List.generate(
              PasteMenuType.values.length,
              (i) => buildItem(PasteMenuType.values[i], i),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildItem(PasteMenuType type, int i) {
    return ValueListenableBuilder(
      valueListenable: selectedIndexNotifier,
      builder: (context, value, child) {
        final isSelected = i == value;
        return SizedBox(
          height: 36,
          child: FlowyButton(
            isSelected: isSelected,
            text: FlowyText(
              type.title,
            ),
            onTap: () => onSelect(type),
          ),
        );
      },
    );
  }

  void changeIndex(int index) => selectedIndexNotifier.value = index;

  KeyEventResult onKeyEvent(focus, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    int index = selectedIndexNotifier.value,
        length = PasteMenuType.values.length;
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      onSelect(PasteMenuType.values[index]);
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      dismiss();
    } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
      dismiss();
    } else if ([LogicalKeyboardKey.arrowUp, LogicalKeyboardKey.arrowLeft]
        .contains(event.logicalKey)) {
      if (index == 0) {
        index = length - 1;
      } else {
        index--;
      }
      changeIndex(index);
      return KeyEventResult.handled;
    } else if ([LogicalKeyboardKey.arrowDown, LogicalKeyboardKey.arrowRight]
        .contains(event.logicalKey)) {
      if (index == length - 1) {
        index = 0;
      } else {
        index++;
      }
      changeIndex(index);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void onSelect(PasteMenuType type) => widget.onSelect.call(type);

  void dismiss() => widget.onDismiss.call();
}

enum PasteMenuType {
  mention,
  url,
  bookmark,
  embed,
}

extension PasteMenuTypeExtension on PasteMenuType {
  String get title {
    switch (this) {
      case PasteMenuType.mention:
        return LocaleKeys.document_plugins_linkPreview_typeSelection_mention
            .tr();
      case PasteMenuType.url:
        return LocaleKeys.document_plugins_linkPreview_typeSelection_URL.tr();
      case PasteMenuType.bookmark:
        return LocaleKeys.document_plugins_linkPreview_typeSelection_bookmark
            .tr();
      case PasteMenuType.embed:
        return LocaleKeys.document_plugins_linkPreview_typeSelection_embed.tr();
    }
  }
}
