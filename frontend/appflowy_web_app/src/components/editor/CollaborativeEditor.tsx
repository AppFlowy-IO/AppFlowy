import { withYHistory } from '@/application/slate-yjs/plugins/withHistory';
import { CollabOrigin } from '@/application/types';
import { withYjs, YjsEditor } from '@/application/slate-yjs/plugins/withYjs';
import EditorEditable from '@/components/editor/Editable';
import { useEditorContext } from '@/components/editor/EditorContext';
import { withPlugins } from '@/components/editor/plugins';
import { getTextCount } from '@/utils/word';
import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { createEditor, Descendant } from 'slate';
import { Slate, withReact } from 'slate-react';
import * as Y from 'yjs';

const defaultInitialValue: Descendant[] = [];

function CollaborativeEditor({ doc }: { doc: Y.Doc }) {
  const context = useEditorContext();
  const readSummary = context.readSummary;
  const uploadFile = context.uploadFile;
  const readOnly = context.readOnly;
  const viewId = context.viewId;
  const onWordCountChange = context.onWordCountChange;
  const localOrigin = CollabOrigin.Local;
  const [, setClock] = useState(0);
  const onContentChange = useCallback((content: Descendant[]) => {
    const wordCount = getTextCount(content);

    onWordCountChange?.(viewId, wordCount);
    setClock((prev) => prev + 1);
  }, [onWordCountChange, viewId]);

  const editor = useMemo(
    () =>
      doc &&
      (withPlugins(
        withReact(
          withYHistory(
            withYjs(createEditor(), doc, {
              readOnly,
              localOrigin,
              readSummary,
              onContentChange,
              uploadFile,
            }),
          ),
          'x-appflowy-fragment',
        ),
      ) as YjsEditor),
    [doc, uploadFile, readOnly, localOrigin, readSummary, onContentChange],
  );
  const [, setIsConnected] = useState(false);

  useEffect(() => {
    if (!editor) return;

    editor.connect();
    setIsConnected(true);

    return () => {
      editor.disconnect();
    };
  }, [editor]);

  return (
    <Slate
      editor={editor}
      initialValue={defaultInitialValue}
    >
      <EditorEditable/>
    </Slate>

  );
}

export default CollaborativeEditor;
