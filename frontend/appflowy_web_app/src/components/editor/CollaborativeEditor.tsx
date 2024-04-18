import { withYjs, YjsEditor } from '@/application/slate-yjs/plugins/withYjs';
import EditorEditable from '@/components/editor/Editable';
import { withPlugins } from '@/components/editor/plugins';
import React, { useEffect, useMemo, useState } from 'react';
import { createEditor, Descendant } from 'slate';
import { Slate, withReact } from 'slate-react';
import * as Y from 'yjs';

const defaultInitialValue: Descendant[] = [];

function CollaborativeEditor({ doc }: { doc: Y.Doc }) {
  const editor = useMemo(() => doc && (withPlugins(withReact(withYjs(createEditor(), doc))) as YjsEditor), [doc]);
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const [_, setIsConnected] = useState(false);

  useEffect(() => {
    if (!editor) return;
    editor.connect();
    setIsConnected(true);

    return () => {
      editor.disconnect();
    };
  }, [editor]);

  return (
    <Slate editor={editor} initialValue={defaultInitialValue}>
      <EditorEditable editor={editor} />
    </Slate>
  );
}

export default CollaborativeEditor;
