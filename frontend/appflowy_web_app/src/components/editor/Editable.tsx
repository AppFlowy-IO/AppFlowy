import { useDecorate } from '@/components/editor/components/blocks/code/useDecorate';
import { Leaf } from '@/components/editor/components/leaf';
import { useEditorContext } from '@/components/editor/EditorContext';
import React, { Suspense, useCallback } from 'react';
import { NodeEntry } from 'slate';
import { Editable, ReactEditor, RenderElementProps } from 'slate-react';
import { Element } from './components/element';
import { Skeleton } from '@mui/material';

const EditorEditable = ({ editor }: { editor: ReactEditor }) => {
  const { readOnly } = useEditorContext();
  const codeDecorate = useDecorate(editor);

  const decorate = useCallback(
    (entry: NodeEntry) => {
      return [...codeDecorate(entry)];
    },
    [codeDecorate]
  );

  const renderElement = useCallback(
    (props: RenderElementProps) => (
      <Suspense fallback={<Skeleton width={'100%'} height={24} />}>
        <Element {...props} />
      </Suspense>
    ),
    []
  );

  return (
    <>
      <Editable
        role={'textbox'}
        decorate={decorate}
        className={'px-16 outline-none focus:outline-none max-md:px-4'}
        renderLeaf={Leaf}
        renderElement={renderElement}
        readOnly={readOnly}
        spellCheck={false}
        autoCorrect={'off'}
        autoComplete={'off'}
      />
    </>
  );
};

export default EditorEditable;
