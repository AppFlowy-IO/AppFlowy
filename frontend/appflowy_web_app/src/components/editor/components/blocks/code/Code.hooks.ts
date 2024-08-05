import { CodeNode } from '@/components/editor/editor.type';
import { useEditorContext } from '@/components/editor/EditorContext';
import { useCallback, useEffect } from 'react';
import { ReactEditor, useSlateStatic } from 'slate-react';
import { Element as SlateElement, Transforms } from 'slate';
import Prism from 'prismjs';

export function useCodeBlock(node: CodeNode) {
  const language = node.data.language;
  const editor = useSlateStatic() as ReactEditor;
  const addCodeGrammars = useEditorContext().addCodeGrammars;

  useEffect(() => {
    void (async () => {
      const path = ReactEditor.findPath(editor, node);
      let detectedLanguage = language;

      if (!language) {
        const codeSnippet = editor.string(path);
        const script = document.createElement('script');

        script.src = 'https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.5.1/highlight.min.js';
        document.body.appendChild(script);
        const promise = new Promise((resolve) => {
          script.onload = () => {
            resolve(true);
          };
        });

        await promise;

        detectedLanguage = window.hljs.highlightAuto(codeSnippet).language || 'plaintext';
      }

      const prismLanguage = Prism.languages[detectedLanguage.toLowerCase()];

      if (!prismLanguage) {
        const script = document.createElement('script');

        script.src = `https://cdnjs.cloudflare.com/ajax/libs/prism/1.26.0/components/prism-${detectedLanguage.toLowerCase()}.min.js`;
        document.body.appendChild(script);
        script.onload = () => {
          addCodeGrammars?.(node.blockId, detectedLanguage);
        };
      } else {
        addCodeGrammars?.(node.blockId, detectedLanguage);
      }
    })();
  }, [addCodeGrammars, editor, language, node]);

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
