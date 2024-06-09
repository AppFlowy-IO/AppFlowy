import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

final todoListToolbarItem = AppFlowyMobileToolbarItem(
  itemBuilder: (context, editorState, _, __, onAction) {
    return AppFlowyMobileToolbarIconItem(
      editorState: editorState,
      shouldListenToToggledStyle: true,
      keepSelectedStatus: true,
      isSelected: () => false,
      icon: FlowySvgs.m_toolbar_checkbox_m,
      onTap: () async {
        await editorState.convertBlockType(
          TodoListBlockKeys.type,
          extraAttributes: {
            TodoListBlockKeys.checked: false,
          },
        );
      },
    );
  },
);

final numberedListToolbarItem = AppFlowyMobileToolbarItem(
  itemBuilder: (context, editorState, _, __, onAction) {
    final isSelected =
        editorState.isBlockTypeSelected(NumberedListBlockKeys.type);
    return AppFlowyMobileToolbarIconItem(
      editorState: editorState,
      shouldListenToToggledStyle: true,
      keepSelectedStatus: true,
      isSelected: () => isSelected,
      icon: FlowySvgs.m_toolbar_numbered_list_m,
      onTap: () async {
        await editorState.convertBlockType(
          NumberedListBlockKeys.type,
        );
      },
    );
  },
);

final bulletedListToolbarItem = AppFlowyMobileToolbarItem(
  itemBuilder: (context, editorState, _, __, onAction) {
    final isSelected =
        editorState.isBlockTypeSelected(BulletedListBlockKeys.type);
    return AppFlowyMobileToolbarIconItem(
      editorState: editorState,
      shouldListenToToggledStyle: true,
      keepSelectedStatus: true,
      isSelected: () => isSelected,
      icon: FlowySvgs.m_toolbar_bulleted_list_m,
      onTap: () async {
        await editorState.convertBlockType(
          BulletedListBlockKeys.type,
        );
      },
    );
  },
);
