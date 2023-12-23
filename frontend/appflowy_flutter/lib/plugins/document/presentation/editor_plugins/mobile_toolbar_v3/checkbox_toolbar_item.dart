import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

final todoListToolbarItem = AppFlowyMobileToolbarItem(
  itemBuilder: (context, editorState, _, __, onAction) {
    final isSelected = editorState.isBlockTypeSelected(TodoListBlockKeys.type);
    return AppFlowyMobileToolbarIconItem(
      keepSelectedStatus: true,
      isSelected: () => isSelected,
      icon: FlowySvgs.m_toolbar_checkbox_s,
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
