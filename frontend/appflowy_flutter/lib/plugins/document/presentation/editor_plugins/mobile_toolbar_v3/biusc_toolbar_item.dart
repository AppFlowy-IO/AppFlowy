import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/aa_menu/_color_list.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/widgets.dart';

final boldToolbarItem = AppFlowyMobileToolbarItem(
  itemBuilder: (context, editorState, _, __, onAction) {
    return AppFlowyMobileToolbarIconItem(
      editorState: editorState,
      shouldListenToToggledStyle: true,
      isSelected: () =>
          editorState.isTextDecorationSelected(
            AppFlowyRichTextKeys.bold,
          ) &&
          editorState.toggledStyle[AppFlowyRichTextKeys.bold] != false,
      icon: FlowySvgs.m_toolbar_bold_m,
      onTap: () async => editorState.toggleAttribute(
        AppFlowyRichTextKeys.bold,
        selectionExtraInfo: {
          selectionExtraInfoDisableFloatingToolbar: true,
        },
      ),
    );
  },
);

final italicToolbarItem = AppFlowyMobileToolbarItem(
  itemBuilder: (context, editorState, _, __, onAction) {
    return AppFlowyMobileToolbarIconItem(
      editorState: editorState,
      shouldListenToToggledStyle: true,
      isSelected: () => editorState.isTextDecorationSelected(
        AppFlowyRichTextKeys.italic,
      ),
      icon: FlowySvgs.m_toolbar_italic_m,
      onTap: () async => editorState.toggleAttribute(
        AppFlowyRichTextKeys.italic,
        selectionExtraInfo: {
          selectionExtraInfoDisableFloatingToolbar: true,
        },
      ),
    );
  },
);

final underlineToolbarItem = AppFlowyMobileToolbarItem(
  itemBuilder: (context, editorState, _, __, onAction) {
    return AppFlowyMobileToolbarIconItem(
      editorState: editorState,
      shouldListenToToggledStyle: true,
      isSelected: () => editorState.isTextDecorationSelected(
        AppFlowyRichTextKeys.underline,
      ),
      icon: FlowySvgs.m_toolbar_underline_m,
      onTap: () async => editorState.toggleAttribute(
        AppFlowyRichTextKeys.underline,
        selectionExtraInfo: {
          selectionExtraInfoDisableFloatingToolbar: true,
        },
      ),
    );
  },
);

final strikethroughToolbarItem = AppFlowyMobileToolbarItem(
  itemBuilder: (context, editorState, _, __, onAction) {
    return AppFlowyMobileToolbarIconItem(
      editorState: editorState,
      shouldListenToToggledStyle: true,
      isSelected: () => editorState.isTextDecorationSelected(
        AppFlowyRichTextKeys.strikethrough,
      ),
      icon: FlowySvgs.m_toolbar_strike_m,
      onTap: () async => editorState.toggleAttribute(
        AppFlowyRichTextKeys.strikethrough,
        selectionExtraInfo: {
          selectionExtraInfoDisableFloatingToolbar: true,
        },
      ),
    );
  },
);

final colorToolbarItem = AppFlowyMobileToolbarItem(
  itemBuilder: (context, editorState, service, __, onAction) {
    return AppFlowyMobileToolbarIconItem(
      editorState: editorState,
      shouldListenToToggledStyle: true,
      icon: FlowySvgs.m_aa_font_color_m,
      iconBuilder: (context) {
        String? getColor(String key) {
          final selection = editorState.selection;
          if (selection == null) {
            return null;
          }
          String? color = editorState.toggledStyle[key];
          if (color == null) {
            if (selection.isCollapsed && selection.startIndex != 0) {
              color = editorState.getDeltaAttributeValueInSelection<String>(
                key,
                selection.copyWith(
                  start: selection.start.copyWith(
                    offset: selection.startIndex - 1,
                  ),
                ),
              );
            } else {
              color = editorState.getDeltaAttributeValueInSelection<String>(
                key,
              );
            }
          }
          return color;
        }

        final textColor = getColor(AppFlowyRichTextKeys.textColor);
        final backgroundColor = getColor(AppFlowyRichTextKeys.backgroundColor);

        return Container(
          width: 40,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            color: backgroundColor?.tryToColor(),
          ),
          child: FlowySvg(
            FlowySvgs.m_aa_font_color_m,
            color: textColor?.tryToColor(),
          ),
        );
      },
      onTap: () {
        service.closeKeyboard();
        editorState.updateSelectionWithReason(
          editorState.selection,
          extraInfo: {
            selectionExtraInfoDisableMobileToolbarKey: true,
            selectionExtraInfoDisableFloatingToolbar: true,
            selectionExtraInfoDoNotAttachTextService: true,
          },
        );
        keepEditorFocusNotifier.increase();
        showTextColorAndBackgroundColorPicker(
          context,
          editorState: editorState,
          selection: editorState.selection!,
        );
      },
    );
  },
);
