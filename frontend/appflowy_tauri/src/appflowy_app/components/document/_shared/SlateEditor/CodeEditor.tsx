import React from 'react';
import { CodeEditorProps } from '$app/interfaces/document';
import { Editable, Slate } from 'slate-react';
import { useEditor } from '$app/components/document/_shared/SlateEditor/useEditor';
import { decorateCode } from '$app/components/document/_shared/SlateEditor/decorateCode';
import { CodeLeaf, CodeBlockElement } from '$app/components/document/_shared/SlateEditor/CodeElements';

function CodeEditor({ language, ...props }: CodeEditorProps) {
  const { editor, onChange, value, onDOMBeforeInput, decorate, ref, onKeyDown, onBlur } = useEditor({
    ...props,
    isCodeBlock: true,
  });

  return (
    <div ref={ref}>
      <Slate editor={editor} onChange={onChange} value={value}>
        <Editable
          decorate={(entry) => {
            const codeRange = decorateCode(entry, language);
            const range = decorate?.(entry) || [];
            return [...range, ...codeRange];
          }}
          renderLeaf={CodeLeaf}
          renderElement={CodeBlockElement}
          onKeyDown={onKeyDown}
          onDOMBeforeInput={onDOMBeforeInput}
          onBlur={onBlur}
        />
      </Slate>
    </div>
  );
}

export default React.memo(CodeEditor);
