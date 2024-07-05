import { YDoc } from '@/application/collab.type';
import CollaborativeEditor from '@/components/editor/CollaborativeEditor';
import { defaultLayoutStyle, EditorContextProvider, EditorContextState } from '@/components/editor/EditorContext';
import React, { memo } from 'react';
import './editor.scss';

export interface EditorProps extends EditorContextState {
  doc: YDoc;
}

export const Editor = memo(({ doc, layoutStyle = defaultLayoutStyle, ...props }: EditorProps) => {
  const [codeGrammars, setCodeGrammars] = React.useState<Record<string, string>>({});

  const handleAddCodeGrammars = React.useCallback((blockId: string, grammar: string) => {
    setCodeGrammars((prev) => ({ ...prev, [blockId]: grammar }));
  }, []);

  return (
    <EditorContextProvider
      {...props}
      codeGrammars={codeGrammars}
      addCodeGrammars={handleAddCodeGrammars}
      layoutStyle={layoutStyle}
    >
      <CollaborativeEditor doc={doc} />
    </EditorContextProvider>
  );
});

export default Editor;
