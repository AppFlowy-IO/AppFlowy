import { ReactEditor } from 'slate-react';
import { EditorInlineNodeType, inlineNodeTypes } from '$app/application/document/document.types';
import { Element } from 'slate';

export function withInlines(editor: ReactEditor) {
  const { isInline, isElementReadOnly, isSelectable, isVoid, markableVoid } = editor;

  const matchInlineType = (element: Element) => {
    return inlineNodeTypes.includes(element.type as EditorInlineNodeType);
  };

  editor.isInline = (element) => {
    return matchInlineType(element) || isInline(element);
  };

  editor.isVoid = (element) => {
    return matchInlineType(element) || isVoid(element);
  };

  editor.markableVoid = (element) => {
    return matchInlineType(element) || markableVoid(element);
  };

  editor.isElementReadOnly = (element) =>
    inlineNodeTypes.includes(element.type as EditorInlineNodeType) || isElementReadOnly(element);

  editor.isSelectable = (element) =>
    !inlineNodeTypes.includes(element.type as EditorInlineNodeType) && isSelectable(element);

  return editor;
}
