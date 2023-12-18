import React, { memo } from 'react';
import { EditorProps } from '../../application/document/document.types';

import { Toaster } from 'react-hot-toast';
import { CollaborativeEditor } from '$app/components/editor/components/editor';
import { EditorIdProvider } from '$app/components/editor/Editor.hooks';

export function Editor(props: EditorProps) {
  return (
    <EditorIdProvider value={props.id}>
      <CollaborativeEditor {...props} />
      <Toaster />
    </EditorIdProvider>
  );
}

export default memo(Editor);
