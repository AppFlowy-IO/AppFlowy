import { useCallback } from 'react';
import { ReactEditor, useSlateStatic } from 'slate-react';
import { Element as SlateElement, Transforms } from 'slate';
import { CodeNode } from '$app/application/document/document.types';

export function useCodeBlock(node: CodeNode) {
  const language = node.data.language;
  const editor = useSlateStatic() as ReactEditor;
  const handleChangeLanguage = useCallback(
    (newLang: string) => {
      const path = ReactEditor.findPath(editor, node);
      const newProperties = {
        data: {
          language: newLang,
        },
      } as Partial<SlateElement>;

      Transforms.setNodes(editor, newProperties, { at: path });
    },
    [editor, node]
  );

  return {
    language,
    handleChangeLanguage,
  };
}
