import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/_color_list.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

final boldToolbarItem = AppFlowyMobileToolbarItem(
  pilotAtExpandedSelection: true,
  itemBuilder: (context, editorState, _, __, onAction) {
    return AppFlowyMobileToolbarIconItem(
      isSelected: () => editorState.isTextDecorationSelected(
        AppFlowyRichTextKeys.bold,
      ),
      icon: FlowySvgs.m_toolbar_bold_s,
      onTap: () async => await editorState.toggleAttribute(
        AppFlowyRichTextKeys.bold,
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
      onTap: () async => await editorState.toggleAttribute(
        AppFlowyRichTextKeys.italic,
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
      onTap: () async => await editorState.toggleAttribute(
        AppFlowyRichTextKeys.underline,
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
            disableMobileToolbarKey: true,
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
