import { ReactEditor } from 'slate-react';
import { EditorNodeType } from '$app/application/document/document.types';

export function withDividerPlugin(editor: ReactEditor) {
  const { isElementReadOnly, isSelectable, isEmpty } = editor;

  editor.isElementReadOnly = (element) => {
    return element.type === EditorNodeType.DividerBlock || isElementReadOnly(element);
  };

  editor.isSelectable = (element) => {
    return element.type !== EditorNodeType.DividerBlock || isSelectable(element);
  };

  editor.isEmpty = (element) => {
    return element.type !== EditorNodeType.DividerBlock && isEmpty(element);
  };

  return editor;
}
