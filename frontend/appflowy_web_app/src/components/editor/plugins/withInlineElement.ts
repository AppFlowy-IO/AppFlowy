import { InlineBlockType } from '@/application/document.type';
import { ReactEditor } from 'slate-react';
import { Element } from 'slate';

export function withInlines(editor: ReactEditor) {
  const { isInline, isElementReadOnly, isSelectable, isVoid, markableVoid } = editor;

  const matchInlineType = (element: Element) => {
    return Object.values(InlineBlockType).includes(element.type as InlineBlockType);
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
    Object.values(InlineBlockType).includes(element.type as InlineBlockType) || isElementReadOnly(element);

  editor.isSelectable = (element) =>
    !Object.values(InlineBlockType).includes(element.type as InlineBlockType) && isSelectable(element);

  return editor;
}
