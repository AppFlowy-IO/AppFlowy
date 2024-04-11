import { withYjs } from '@/application/slate-yjs/plugins/withYjs';
import React, { useEffect, useMemo, useState } from 'react';
import { createEditor } from 'slate';
import * as Y from 'yjs';
import { Slate, Editable } from 'slate-react';

function Editor ({
  doc,
}: {
  doc: Y.Doc
}) {
  const editor = useMemo(() => withYjs(createEditor(), doc), [doc]);
  const [isConnected, setIsConnected] = useState(false);

  useEffect(() => {
    editor.connect();
    setIsConnected(true);

    return () => {
      editor.disconnect();
    };
  }, [editor]);
  console.log(editor.children);
  return (
    <Slate editor={editor} initialValue={[]}>
      <Editable readOnly />
    </Slate>
  );
}

export default Editor;