import React from 'react';
import { EditorProps } from '$app/interfaces/document';
import { Editable, Slate } from 'slate-react';
import { useEditor } from '$app/components/document/_shared/SlateEditor/useEditor';
import TextLeaf from '$app/components/document/_shared/SlateEditor/TextLeaf';
import { TextElement } from '$app/components/document/_shared/SlateEditor/TextElement';

function TextEditor({ placeholder = "Type '/' for commands", ...props }: EditorProps) {
  const { editor, onChange, value, ref, ...editableProps } = useEditor(props);

  return (
    <div ref={ref} className={'px-1 py-0.5'}>
      <Slate editor={editor} onChange={onChange} value={value}>
        <Editable
          renderLeaf={(leafProps) => <TextLeaf {...leafProps} editor={editor} />}
          placeholder={placeholder}
          renderElement={TextElement}
          {...editableProps}
        />
      </Slate>
    </div>
  );
}

export default React.memo(TextEditor);
