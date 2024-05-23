import { CollabOrigin, YjsFolderKey } from '@/application/collab.type';
import { useViewSelector } from '@/application/folder-yjs';
import { withYjs, YjsEditor } from '@/application/slate-yjs/plugins/withYjs';
import { useId } from '@/components/_shared/context-provider/IdProvider';
import { CustomEditor } from '@/components/editor/command';
import EditorEditable from '@/components/editor/Editable';
import { useEditorContext } from '@/components/editor/EditorContext';
import { withPlugins } from '@/components/editor/plugins';
import React, { useEffect, useMemo, useState } from 'react';
import { createEditor, Descendant } from 'slate';
import { Slate, withReact } from 'slate-react';
import * as Y from 'yjs';

const defaultInitialValue: Descendant[] = [];

function CollaborativeEditor({ doc, includeRoot = true }: { doc: Y.Doc; includeRoot?: boolean }) {
  const viewId = useId()?.objectId || '';
  const { view } = useViewSelector(viewId);
  const title = includeRoot ? view?.get(YjsFolderKey.name) : undefined;
  const context = useEditorContext();
  // if readOnly, collabOrigin is Local, otherwise RemoteSync
  const localOrigin = context.readOnly ? CollabOrigin.Local : CollabOrigin.LocalSync;
  const editor = useMemo(
    () =>
      doc &&
      (withPlugins(
        withReact(
          withYjs(createEditor(), doc, {
            localOrigin,
            includeRoot,
          })
        )
      ) as YjsEditor),
    [doc, localOrigin, includeRoot]
  );
  const [connected, setIsConnected] = useState(false);

  useEffect(() => {
    if (!editor) return;
    editor.connect();
    setIsConnected(true);

    return () => {
      editor.disconnect();
    };
  }, [editor]);

  useEffect(() => {
    if (!editor || !connected || title === undefined) return;
    CustomEditor.setDocumentTitle(editor, title);
  }, [editor, title, connected]);

  return (
    <Slate editor={editor} initialValue={defaultInitialValue}>
      <EditorEditable editor={editor} />
    </Slate>
  );
}

export default CollaborativeEditor;
