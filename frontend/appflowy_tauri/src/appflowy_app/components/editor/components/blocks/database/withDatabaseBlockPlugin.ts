import { ReactEditor } from 'slate-react';
import { EditorNodeType } from '$app/application/document/document.types';

export function withDatabaseBlockPlugin(editor: ReactEditor) {
  const { isElementReadOnly, isSelectable, isEmpty } = editor;

  editor.isElementReadOnly = (element) => {
    return element.type === EditorNodeType.GridBlock || isElementReadOnly(element);
  };

  editor.isSelectable = (element) => {
    return element.type !== EditorNodeType.GridBlock || isSelectable(element);
  };

  editor.isEmpty = (element) => {
    return element.type !== EditorNodeType.GridBlock && isEmpty(element);
  };

  return editor;
}
