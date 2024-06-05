import { YDoc } from '@/application/collab.type';
import CollaborativeEditor from '@/components/editor/CollaborativeEditor';
import { defaultLayoutStyle, EditorContextProvider, EditorLayoutStyle } from '@/components/editor/EditorContext';
import React, { memo } from 'react';
import './editor.scss';

export interface EditorProps {
  readOnly: boolean;
  doc: YDoc;
  layoutStyle?: EditorLayoutStyle;
}

export const Editor = memo(({ readOnly, doc, layoutStyle = defaultLayoutStyle }: EditorProps) => {
  return (
    <EditorContextProvider layoutStyle={layoutStyle} readOnly={readOnly}>
      <CollaborativeEditor doc={doc} />
    </EditorContextProvider>
  );
});

export default Editor;
