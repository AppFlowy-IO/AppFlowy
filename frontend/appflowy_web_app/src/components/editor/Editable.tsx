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

  const renderElement = useCallback((props: RenderElementProps) => {
    return (
      <Suspense fallback={<Skeleton width={'100%'} height={24} />}>
        <Element {...props} />
      </Suspense>
    );
  }, []);

  return (
    <>
      <Editable
        role={'textbox'}
        decorate={(entry: NodeEntry) => {
          const decoration = codeDecorate?.(entry);

          return decoration || [];
        }}
        className={'outline-none w-[964px] min-w-0 max-w-full px-6 focus:outline-none'}
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
