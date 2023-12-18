import { ReactEditor } from 'slate-react';
import { EditorNodeType } from '$app/application/document/document.types';

export function withMathEquationPlugin(editor: ReactEditor) {
  const { isElementReadOnly, isSelectable, isEmpty } = editor;

  editor.isElementReadOnly = (element) => {
    return element.type === EditorNodeType.EquationBlock || isElementReadOnly(element);
  };

  editor.isSelectable = (element) => {
    return element.type !== EditorNodeType.EquationBlock || isSelectable(element);
  };

  editor.isEmpty = (element) => {
    return element.type !== EditorNodeType.EquationBlock && isEmpty(element);
  };

  return editor;
}
