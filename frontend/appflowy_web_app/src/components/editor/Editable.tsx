import { useDecorate } from '@/components/editor/components/blocks/code/useDecorate';
import { Element } from '@/components/editor/components/element';
import { Leaf } from '@/components/editor/components/leaf';
import { useEditorContext } from '@/components/editor/EditorContext';
import React from 'react';
import { Editable } from 'slate-react';

const EditorEditable = () => {
  const codeDecorate = useDecorate();
  const { readOnly } = useEditorContext();

  return (
    <Editable
      role={'textbox'}
      decorate={codeDecorate}
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
