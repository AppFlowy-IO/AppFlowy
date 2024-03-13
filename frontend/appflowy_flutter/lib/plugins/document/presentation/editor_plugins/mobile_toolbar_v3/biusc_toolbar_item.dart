import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/aa_menu/_color_list.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

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
