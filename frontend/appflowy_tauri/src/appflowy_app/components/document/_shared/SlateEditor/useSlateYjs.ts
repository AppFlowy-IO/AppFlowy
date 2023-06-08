import Delta from 'quill-delta';
import { useEffect, useMemo, useRef } from 'react';
import * as Y from 'yjs';
import { convertToSlateValue } from '$app/utils/document/slate_editor';
import { slateNodesToInsertDelta, withYjs, YjsEditor } from '@slate-yjs/core';
import { withReact } from 'slate-react';
import { createEditor } from 'slate';

export function useSlateYjs({ delta }: { delta?: Delta }) {
  const yTextRef = useRef<Y.Text>();
  const sharedType = useMemo(() => {
    const yDoc = new Y.Doc();
    const sharedType = yDoc.get('content', Y.XmlText) as Y.XmlText;
    const value = convertToSlateValue(delta || new Delta());
    const insertDelta = slateNodesToInsertDelta(value);
    sharedType.applyDelta(insertDelta);
    yTextRef.current = insertDelta[0].insert as Y.Text;
    return sharedType;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const editor = useMemo(() => withYjs(withReact(createEditor()), sharedType), []);

  // Connect editor in useEffect to comply with concurrent mode requirements.
  useEffect(() => {
    YjsEditor.connect(editor);
    return () => {
      yTextRef.current = undefined;
      YjsEditor.disconnect(editor);
    };
  }, [editor]);

  useEffect(() => {
    const yText = yTextRef.current;
    if (!yText) return;
    const oldContents = new Delta(yText.toDelta());
    const diffDelta = oldContents.diff(delta || new Delta());
    if (diffDelta.ops.length === 0) return;
    yText.applyDelta(diffDelta.ops);
  }, [delta, editor]);

  return editor;
}
