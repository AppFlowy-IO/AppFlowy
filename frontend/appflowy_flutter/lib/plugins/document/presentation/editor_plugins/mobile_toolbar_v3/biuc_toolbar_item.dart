import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

final boldToolbarItem = AppFlowyMobileToolbarItem(
  pilotAtExpandedSelection: true,
  itemBuilder: (context, editorState, _, onAction) {
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
  itemBuilder: (context, editorState, _, onAction) {
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
  itemBuilder: (context, editorState, _, onAction) {
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
  itemBuilder: (context, editorState, _, onAction) {
    return AppFlowyMobileToolbarIconItem(
      icon: FlowySvgs.m_toolbar_color_s,
      onTap: () {},
    );
  },
);
