import 'package:appflowy_editor/appflowy_editor.dart' hide Log;

final customImageMenuItem = SelectionMenuItem(
  name: AppFlowyEditorLocalizations.current.image,
  icon: (editorState, isSelected, style) => SelectionMenuIconWidget(
    name: 'image',
    isSelected: isSelected,
    style: style,
  ),
  keywords: ['image', 'picture', 'img', 'photo'],
  handler: (editorState, menuService, context) async {
    return await editorState.insertImageNode('');
  },
);
