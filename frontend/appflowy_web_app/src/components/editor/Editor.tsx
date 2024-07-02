import { YDoc } from '@/application/collab.type';
import CollaborativeEditor from '@/components/editor/CollaborativeEditor';
import { defaultLayoutStyle, EditorContextProvider, EditorContextState } from '@/components/editor/EditorContext';
import React, { memo } from 'react';
import './editor.scss';

export interface EditorProps extends EditorContextState {
  doc: YDoc;
}

export const Editor = memo(({ doc, layoutStyle = defaultLayoutStyle, ...props }: EditorProps) => {
  return (
    <EditorContextProvider {...props} layoutStyle={layoutStyle}>
      <CollaborativeEditor doc={doc} />
    </EditorContextProvider>
  );
});

export default Editor;
