import React from 'react';
import { useEditor } from '$app/components/document/_shared/QuillEditor/useEditor';
import 'quill/dist/quill.snow.css';
import './Editor.css';
import { EditorProps } from '$app/interfaces/document';

function Editor({
  value,
  onChange,
  onSelectionChange,
  selection,
  placeholder = "Type '/' for commands",
  ...props
}: EditorProps) {
  const { ref, editor } = useEditor({
    value,
    onChange,
    onSelectionChange,
    selection,
    placeholder,
  });
  return (
    <div className={'min-h-[30px]'}>
      <div ref={ref} {...props} />
      {!editor && <div className={'px-0.5 py-1 text-shade-4'}>{placeholder}</div>}
    </div>
  );
}

export default React.memo(Editor);
