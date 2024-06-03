import { YDoc } from '@/application/collab.type';
import CollaborativeEditor from '@/components/editor/CollaborativeEditor';
import { EditorContextProvider } from '@/components/editor/EditorContext';
import React from 'react';
import './editor.scss';

export const Editor = ({
  readOnly,
  doc,
  includeRoot = true,
}: {
  readOnly: boolean;
  doc: YDoc;
  includeRoot?: boolean;
}) => {
  return (
    <EditorContextProvider readOnly={readOnly}>
      <CollaborativeEditor doc={doc} includeRoot={includeRoot} />
    </EditorContextProvider>
  );
};

export default Editor;
