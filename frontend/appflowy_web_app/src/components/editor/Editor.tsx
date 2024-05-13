import { YDoc } from '@/application/collab.type';
import CollaborativeEditor from '@/components/editor/CollaborativeEditor';
import { EditorContextProvider } from '@/components/editor/EditorContext';
import React from 'react';
import './editor.scss';

export const Editor = ({ readOnly, doc }: { readOnly: boolean; doc: YDoc }) => {
  return (
    <EditorContextProvider readOnly={readOnly}>
      <CollaborativeEditor doc={doc} />
    </EditorContextProvider>
  );
};

export default Editor;
