import React from 'react';
import { EditorProps } from '$app/interfaces/document';
import { Editable, Slate } from 'slate-react';
import { useEditor } from '$app/components/document/_shared/SlateEditor/useEditor';
import TextLeaf from '$app/components/document/_shared/SlateEditor/TextLeaf';
import { TextElement } from '$app/components/document/_shared/SlateEditor/TextElement';

function TextEditor({ placeholder = "Type '/' for commands", ...props }: EditorProps) {
  const { editor, onChange, value, onDOMBeforeInput, decorate, ref, onKeyDown, onBlur } = useEditor(props);

  return (
    <div ref={ref} className={'py-0.5'}>
      <Slate editor={editor} onChange={onChange} value={value}>
        <Editable
          onKeyDown={onKeyDown}
          onDOMBeforeInput={onDOMBeforeInput}
          decorate={decorate}
          renderLeaf={TextLeaf}
          placeholder={placeholder}
          onBlur={onBlur}
          renderElement={TextElement}
        />
      </Slate>
    </div>
  );
}

export default React.memo(TextEditor);
