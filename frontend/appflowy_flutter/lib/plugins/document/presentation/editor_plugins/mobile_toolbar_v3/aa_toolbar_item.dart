import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/aa_menu/_align_items.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/aa_menu/_bius_items.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/aa_menu/_block_items.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/aa_menu/_color_item.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/aa_menu/_font_item.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/aa_menu/_heading_and_text_items.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/aa_menu/_indent_items.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/aa_menu/_toolbar_theme.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

final aaToolbarItem = AppFlowyMobileToolbarItem(
  itemBuilder: (context, editorState, service, onMenu, _) {
    return AppFlowyMobileToolbarIconItem(
      editorState: editorState,
      isSelected: () => service.showMenuNotifier.value,
      keepSelectedStatus: true,
      icon: FlowySvgs.m_toolbar_aa_m,
      onTap: () => onMenu?.call(),
    );
  },
  menuBuilder: (context, editorState, service) {
    final selection = editorState.selection;
    if (selection == null) {
      return const SizedBox.shrink();
    }
    return _TextDecorationMenu(
      editorState,
      selection,
      service,
    );
  },
);

class _TextDecorationMenu extends StatefulWidget {
  const _TextDecorationMenu(
    this.editorState,
    this.selection,
    this.service,
  );

  final EditorState editorState;
  final Selection selection;
  final AppFlowyMobileToolbarWidgetService service;

  @override
  State<_TextDecorationMenu> createState() => _TextDecorationMenuState();
}

class _TextDecorationMenuState extends State<_TextDecorationMenu> {
  EditorState get editorState => widget.editorState;

  @override
  Widget build(BuildContext context) {
    final theme = ToolbarColorExtension.of(context);
    return ColoredBox(
      color: theme.toolbarMenuBackgroundColor,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(
                top: 16,
                bottom: 20,
                left: 12,
                right: 12,
              ) *
              context.scale,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HeadingsAndTextItems(
                editorState: editorState,
              ),
              const ScaledVSpace(),
              Row(
                children: [
                  BIUSItems(
                    editorState: editorState,
                  ),
                  const Spacer(),
                  ColorItem(
                    editorState: editorState,
                    service: widget.service,
                  ),
                ],
              ),
              const ScaledVSpace(),
              Row(
                children: [
                  BlockItems(
                    service: widget.service,
                    editorState: editorState,
                  ),
                  const Spacer(),
                  AlignItems(
                    editorState: editorState,
                  ),
                ],
              ),
              const ScaledVSpace(),
              Row(
                children: [
                  FontFamilyItem(
                    editorState: editorState,
                  ),
                  const Spacer(),
                  IndentAndOutdentItems(
                    service: widget.service,
                    editorState: editorState,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
