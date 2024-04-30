import { useDecorate } from '@/components/editor/components/blocks/code/useDecorate';
import { Leaf } from '@/components/editor/components/leaf';
import { useEditorContext } from '@/components/editor/EditorContext';
import React, { useCallback } from 'react';
import { NodeEntry } from 'slate';
import { Editable, ReactEditor } from 'slate-react';
import { Element } from './components/element';

const EditorEditable = ({ editor }: { editor: ReactEditor }) => {
  const { readOnly } = useEditorContext();
  const codeDecorate = useDecorate(editor);

  const decorate = useCallback(
    (entry: NodeEntry) => {
      return [...codeDecorate(entry)];
    },
    [codeDecorate]
  );

  return (
    <Editable
      role={'textbox'}
      decorate={decorate}
      className={'px-16 outline-none focus:outline-none max-md:px-4'}
      renderLeaf={Leaf}
      renderElement={Element}
      readOnly={readOnly}
      spellCheck={false}
      autoCorrect={'off'}
      autoComplete={'off'}
    />
  );
};

export default EditorEditable;
