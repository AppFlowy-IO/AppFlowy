import React from 'react';
import { CodeEditorProps } from '$app/interfaces/document';
import { Editable, Slate } from 'slate-react';
import { useEditor } from '$app/components/document/_shared/SlateEditor/useEditor';
import { decorateCode } from '$app/components/document/_shared/SlateEditor/decorateCode';
import { CodeBlockElement } from '$app/components/document/_shared/SlateEditor/CodeElements';
import TextLeaf from '$app/components/document/_shared/SlateEditor/TextLeaf';

function CodeEditor({ language, ...props }: CodeEditorProps) {
  const { editor, onChange, value, ref, ...editableProps } = useEditor({
    ...props,
    isCodeBlock: true,
  });

  return (
    <div ref={ref}>
      <Slate editor={editor} onChange={onChange} value={value}>
        <Editable
          {...editableProps}
          decorate={(entry) => {
            const codeRange = decorateCode(entry, language);
            const range = editableProps.decorate?.(entry) || [];
            return [...range, ...codeRange];
          }}
          renderLeaf={(leafProps) => <TextLeaf editor={editor} {...leafProps} isCodeBlock={true} />}
          renderElement={CodeBlockElement}
        />
      </Slate>
    </div>
  );
}

export default React.memo(CodeEditor);
