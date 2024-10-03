import { YjsEditor } from '@/application/slate-yjs';
import { CustomEditor } from '@/application/slate-yjs/command';
import { useDecorate } from '@/components/editor/components/blocks/code/useDecorate';
import { Leaf } from '@/components/editor/components/leaf';
import { useEditorContext } from '@/components/editor/EditorContext';
import React, { Suspense, useCallback } from 'react';
import { NodeEntry, Range } from 'slate';
import { Editable, RenderElementProps, useSlate } from 'slate-react';
import { Element } from './components/element';
import { Skeleton } from '@mui/material';

const EditorEditable = () => {
  const { readOnly } = useEditorContext();
  const editor = useSlate();

  const codeDecorate = useDecorate(editor);
  const renderElement = useCallback((props: RenderElementProps) => {
    return (
      <Suspense fallback={<Skeleton width={'100%'} height={24} />}>
        <Element {...props} />
      </Suspense>
    );
  }, []);
  const onCompositionStart = useCallback(() => {
    const { selection } = editor;

    if (!selection) return;
    if (Range.isExpanded(selection)) {
      CustomEditor.deleteBlockBackward(editor as YjsEditor, selection);
    }
  }, [editor]);

  return (
    <>
      <Editable
        role={'textbox'}
        decorate={(entry: NodeEntry) => {
          const decoration = codeDecorate?.(entry);

          return decoration || [];
        }}
        className={'outline-none mb-36 w-[964px] min-w-0 max-w-full px-6 focus:outline-none'}
        renderLeaf={Leaf}
        renderElement={renderElement}
        readOnly={readOnly}
        spellCheck={false}
        autoCorrect={'off'}
        autoComplete={'off'}
        onCompositionStart={onCompositionStart}
      />
    </>
  );
};

export default EditorEditable;
