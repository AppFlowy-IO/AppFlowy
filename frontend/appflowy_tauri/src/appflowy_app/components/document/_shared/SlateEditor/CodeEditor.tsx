import React from 'react';
import { CodeEditorProps } from '$app/interfaces/document';
import { Editable, Slate } from 'slate-react';
import { useEditor } from '$app/components/document/_shared/SlateEditor/useEditor';
import { decorateCode } from '$app/components/document/_shared/SlateEditor/decorateCode';
import { CodeBlockElement } from '$app/components/document/_shared/SlateEditor/CodeElements';
import TextLeaf from '$app/components/document/_shared/SlateEditor/TextLeaf';

function CodeEditor({ language, ...props }: CodeEditorProps) {
  const { editor, onChange, value, onDOMBeforeInput, decorate, ref, onKeyDown, onBlur, onMouseDownCapture } = useEditor({
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
          renderLeaf={(leafProps) => <TextLeaf editor={editor} {...leafProps} isCodeBlock={true} />}
          renderElement={CodeBlockElement}
          onKeyDown={onKeyDown}
          onDOMBeforeInput={onDOMBeforeInput}
          onBlur={onBlur}
          onMouseDownCapture={onMouseDownCapture}
        />
      </Slate>
    </div>
  );
}

export default React.memo(CodeEditor);
