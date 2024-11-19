import { BlockPopoverProvider } from '@/components/editor/components/block-popover/BlockPopoverContext';
import { useDecorate } from '@/components/editor/components/blocks/code/useDecorate';
import { Leaf } from '@/components/editor/components/leaf';
import { useEditorContext } from '@/components/editor/EditorContext';
import { useShortcuts } from '@/components/editor/shortcut.hooks';
import { getTextCount } from '@/utils/word';
import { debounce } from 'lodash-es';
import React, { lazy, Suspense, useCallback, useEffect, useMemo } from 'react';
import { BaseRange, Editor, NodeEntry, Range } from 'slate';
import { Editable, RenderElementProps, useSlate } from 'slate-react';
import { Element } from './components/element';
import { Skeleton } from '@mui/material';
import { PanelProvider } from '@/components/editor/components/panels/PanelsContext';

const EditorOverlay = lazy(() => import('@/components/editor/EditorOverlay'));

const EditorEditable = () => {
  const { readOnly, decorateState, setSelectedBlockId, onWordCountChange, viewId } = useEditorContext();
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

  const debounceCalculateWordCount = useMemo(() => {
    return debounce(() => {
      const wordCount = getTextCount(editor.children);

      onWordCountChange?.(viewId, wordCount);
    }, 300);
  }, [onWordCountChange, viewId, editor]);

  useEffect(() => {
    const { onChange } = editor;

    editor.onChange = () => {
      const operations = editor.operations;

      const isSelectionChange = operations.some((operation) => operation.type === 'set_selection');

      if (isSelectionChange) {
        setSelectedBlockId?.(undefined);
      }

      onChange();
      debounceCalculateWordCount();
    };

    return () => {
      editor.onChange = onChange;
    };
  }, [editor, debounceCalculateWordCount, setSelectedBlockId]);

  return (
    <PanelProvider editor={editor}>
      <BlockPopoverProvider editor={editor}>
        <Editable
          role={'textbox'}
          decorate={(entry: NodeEntry) => {
            const codeDecoration = codeDecorate?.(entry);
            const decoration = decorate(entry);

            return [...codeDecoration, ...decoration];
          }}
          className={'outline-none scroll-mb-[100px] scroll-mt-[300px] mb-36 w-[988px] min-w-0 max-w-full max-sm:px-6 px-24 focus:outline-none'}
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
          <Suspense><EditorOverlay /></Suspense>
        }
      </BlockPopoverProvider>
    </PanelProvider>
  );
};

export default EditorEditable;
