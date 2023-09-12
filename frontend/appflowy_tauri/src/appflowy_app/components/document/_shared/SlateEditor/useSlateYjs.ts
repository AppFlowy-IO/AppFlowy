import Delta, { Op } from 'quill-delta';
import { useEffect, useMemo, useState } from 'react';
import * as Y from 'yjs';
import { convertToSlateValue } from '$app/utils/document/slate_editor';
import { slateNodesToInsertDelta, withYjs, YjsEditor } from '@slate-yjs/core';
import { withReact } from 'slate-react';
import { createEditor } from 'slate';
import { withMarkdown } from '$app/components/document/_shared/SlateEditor/markdown';

export function useSlateYjs({ delta, onChange }: { delta?: Delta; onChange: (ops: Op[], newDelta: Delta) => void }) {
  const [yText, setYText] = useState<Y.Text | undefined>(undefined);
  const sharedType = useMemo(() => {
    const yDoc = new Y.Doc();
    const sharedType = yDoc.get('content', Y.XmlText) as Y.XmlText;
    const value = convertToSlateValue(delta || new Delta());
    const insertDelta = slateNodesToInsertDelta(value);

    sharedType.applyDelta(insertDelta);
    setYText(insertDelta[0].insert as Y.Text);
    return sharedType;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const editor = useMemo(() => withYjs(withMarkdown(withReact(createEditor())), sharedType), []);

  // Connect editor in useEffect to comply with concurrent mode requirements.
  useEffect(() => {
    YjsEditor.connect(editor);
    const observer = (event: Y.YTextEvent) => {
      const ops = event.changes.delta as Op[];
      const newDelta = new Delta(yText?.toDelta());

      onChange(ops, newDelta);
    };

    yText?.observe(observer);
    return () => {
      YjsEditor.disconnect(editor);
      yText?.unobserve(observer);
    };
  }, [editor, yText, onChange]);

  useEffect(() => {
    if (!yText) return;
    const oldContents = new Delta(yText.toDelta());
    const diffDelta = oldContents.diff(delta || new Delta());

    if (diffDelta.ops.length === 0) return;
    yText.applyDelta(diffDelta.ops);
  }, [delta, editor, yText]);

  return { editor };
}
