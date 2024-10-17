import { useDecorate } from '@/components/editor/components/blocks/code/useDecorate';
import { Leaf } from '@/components/editor/components/leaf';
import { useEditorContext } from '@/components/editor/EditorContext';
import { useShortcuts } from '@/components/editor/shortcut.hooks';
import React, { lazy, Suspense, useCallback } from 'react';
import { BaseRange, Editor, NodeEntry, Range } from 'slate';
import { Editable, RenderElementProps, useSlate } from 'slate-react';
import { Element } from './components/element';
import { Skeleton } from '@mui/material';

const Toolbars = lazy(() => import('./components/toolbar'));

const EditorEditable = () => {
  const { readOnly, decorateState } = useEditorContext();
  const editor = useSlate();

  const codeDecorate = useDecorate(editor);

  const decorate = useCallback(
    ([, path]: NodeEntry): BaseRange[] => {
      const highlightRanges: (Range & {
        class_name: string;
      })[] = [];

      if (!decorateState) return [];

      Object.values(decorateState).forEach((state) => {
        const intersection = Range.intersection(state.range, Editor.range(editor, path));

        if (intersection) {
          highlightRanges.push({
            ...intersection,
            class_name: state.class_name,
          });
        }
      });

      return highlightRanges;
    },
    [editor, decorateState],
  );
  const renderElement = useCallback((props: RenderElementProps) => {
    return (
      <Suspense
        fallback={<Skeleton
          width={'100%'}
          height={24}
        />}
      >
        <Element {...props} />
      </Suspense>
    );
  }, []);

  const {
    onKeyDown,
  } = useShortcuts(editor);

  const onCompositionStart = useCallback(() => {
    const { selection } = editor;

    if (!selection) return;
    if (Range.isExpanded(selection)) {
      editor.delete();
    }
  }, [editor]);

  return (
    <>

      <Editable
        role={'textbox'}
        decorate={(entry: NodeEntry) => {
          const codeDecoration = codeDecorate?.(entry);
          const decoration = decorate(entry);

          return [...codeDecoration, ...decoration];
        }}
        className={'outline-none mb-36 w-[964px] min-w-0 max-w-full px-6 focus:outline-none'}
        renderLeaf={Leaf}
        renderElement={renderElement}
        readOnly={readOnly}
        spellCheck={false}
        autoCorrect={'off'}
        autoComplete={'off'}
        onCompositionStart={onCompositionStart}
        onKeyDown={onKeyDown}
      />
      {!readOnly &&
        <Suspense>
          <Toolbars />
        </Suspense>
      }
    </>
  );
};

export default EditorEditable;
