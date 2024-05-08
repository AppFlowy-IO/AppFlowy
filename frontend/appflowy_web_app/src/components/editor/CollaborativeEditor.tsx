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

function CollaborativeEditor({ doc }: { doc: Y.Doc }) {
  const context = useEditorContext();
  // if readOnly, collabOrigin is Local, otherwise RemoteSync
  const collabOrigin = context.readOnly ? CollabOrigin.Local : CollabOrigin.LocalSync;
  const editor = useMemo(
    () => doc && (withPlugins(withReact(withYjs(createEditor(), doc, collabOrigin))) as YjsEditor),
    [doc, collabOrigin]
  );
  const [connected, setIsConnected] = useState(false);
  const viewId = useId()?.objectId || '';
  const { view } = useViewSelector(viewId);
  const title = view?.get(YjsFolderKey.name);

  useEffect(() => {
    if (!editor) return;
    editor.connect();
    setIsConnected(true);

    return () => {
      editor.disconnect();
    };
  }, [editor]);

  useEffect(() => {
    if (!editor || !connected) return;
    CustomEditor.setDocumentTitle(editor, title || '');
  }, [editor, title, connected]);

  return (
    <Slate editor={editor} initialValue={defaultInitialValue}>
      <EditorEditable editor={editor} />
    </Slate>
  );
}

export default CollaborativeEditor;
