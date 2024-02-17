import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/_color_list.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

final boldToolbarItem = AppFlowyMobileToolbarItem(
  itemBuilder: (context, editorState, _, __, onAction) {
    return AppFlowyMobileToolbarIconItem(
      isSelected: () => editorState.isTextDecorationSelected(
        AppFlowyRichTextKeys.bold,
      ),
      icon: FlowySvgs.m_toolbar_bold_s,
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
      // keepSelectedStatus: true,
      isSelected: () => editorState.isTextDecorationSelected(
        AppFlowyRichTextKeys.italic,
      ),
      icon: FlowySvgs.m_toolbar_italic_s,
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
      isSelected: () => editorState.isTextDecorationSelected(
        AppFlowyRichTextKeys.underline,
      ),
      icon: FlowySvgs.m_toolbar_underline_s,
      onTap: () async => editorState.toggleAttribute(
        AppFlowyRichTextKeys.underline,
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
      icon: FlowySvgs.m_toolbar_color_s,
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
