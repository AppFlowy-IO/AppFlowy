import { useEffect, useRef, useState } from 'react';
import Quill, { Sources } from 'quill';
import Delta from 'quill-delta';
import { adaptDeltaForQuill } from '$app/utils/document/quill_editor';
import { EditorProps } from '$app/interfaces/document';

/**
 * Here we can use ts-ignore because the quill-delta's version of quill is not uploaded to DefinitelyTyped
 */
export function useEditor({ placeholder, value, onChange, onSelectionChange, selection }: EditorProps) {
  const ref = useRef<HTMLDivElement>(null);
  const [editor, setEditor] = useState<Quill>();

  useEffect(() => {
    if (!ref.current) return;
    const editor = new Quill(ref.current, {
      modules: {
        toolbar: false, // Snow includes toolbar by default
      },
      theme: 'snow',
      formats: ['bold', 'italic', 'underline', 'strike', 'code'],
      placeholder: placeholder || 'Please enter some text...',
    });
    const keyboard = editor.getModule('keyboard');
    // clear all keyboard bindings
    keyboard.bindings = {};
    const initialDelta = new Delta(adaptDeltaForQuill(value?.ops || []));
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    editor.setContents(initialDelta);
    setEditor(editor);
  }, []);

  // listen to text-change event
  useEffect(() => {
    if (!editor) return;
    const onTextChange = (delta: Delta, oldContents: Delta, source: Sources) => {
      const newContents = oldContents.compose(delta);
      const newOps = adaptDeltaForQuill(newContents.ops, true);
      const newDelta = new Delta(newOps);
      onChange?.(newDelta, oldContents, source);
      if (source === 'user') {
        const selection = editor.getSelection(false);
        onSelectionChange?.(selection, null, source);
      }
    };
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    editor.on('text-change', onTextChange);
    return () => {
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      editor.off('text-change', onTextChange);
    };
  }, [editor, onChange, onSelectionChange]);

  // listen to selection-change event
  useEffect(() => {
    const handleSelectionChange = () => {
      if (!editor) return;
      const selection = editor.getSelection(false);
      onSelectionChange?.(selection, null, 'user');
    };
    document.addEventListener('selectionchange', handleSelectionChange);
    return () => {
      document.removeEventListener('selectionchange', handleSelectionChange);
    };
  }, [editor, onSelectionChange]);

  // set value
  useEffect(() => {
    if (!editor) return;
    const content = editor.getContents();

    const newOps = adaptDeltaForQuill(value?.ops || []);
    const newDelta = new Delta(newOps);

    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    const diffDelta = content.diff(newDelta);
    const isSame = diffDelta.ops.length === 0;
    if (isSame) return;
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    editor.updateContents(diffDelta, 'api');
  }, [editor, value]);

  // set Selection
  useEffect(() => {
    if (!editor || !selection) return;
    if (JSON.stringify(selection) === JSON.stringify(editor.getSelection())) return;

    editor.setSelection(selection);
  }, [selection, editor]);

  return {
    ref,
    editor,
  };
}
