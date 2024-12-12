import { YjsEditor } from '@/application/slate-yjs';
import { CustomEditor } from '@/application/slate-yjs/command';
import { ensureBlockText } from '@/application/slate-yjs/utils/yjsOperations';
import { BlockType } from '@/application/types';
import { BlockPopoverProvider } from '@/components/editor/components/block-popover/BlockPopoverContext';
import { useDecorate } from '@/components/editor/components/blocks/code/useDecorate';
import { Leaf } from '@/components/editor/components/leaf';
import { PanelProvider } from '@/components/editor/components/panels/PanelsContext';
import { useEditorContext } from '@/components/editor/EditorContext';
import { useShortcuts } from '@/components/editor/shortcut.hooks';
import { getTextCount } from '@/utils/word';
import { Skeleton } from '@mui/material';
import { debounce } from 'lodash-es';
import React, { lazy, Suspense, useCallback, useEffect, useMemo } from 'react';
import { BaseRange, Editor, NodeEntry, Range, Element as SlateElement, Text } from 'slate';
import { Editable, RenderElementProps, useSlate } from 'slate-react';
import { Element } from './components/element';
import { LeafContext } from '@/components/editor/components/leaf/leaf.hooks';
import HrefPopover from '@/components/editor/components/leaf/href/HrefPopover';

const EditorOverlay = lazy(() => import('@/components/editor/EditorOverlay'));

const EditorEditable = () => {
  const { readOnly, decorateState, onWordCountChange, viewId } = useEditorContext();
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
    if (readOnly) return;
    const { onChange } = editor;

    editor.onChange = () => {

      ensureBlockText(editor as YjsEditor);

      onChange();
      debounceCalculateWordCount();
    };

    return () => {
      editor.onChange = onChange;
    };
  }, [editor, debounceCalculateWordCount, readOnly]);

  const handleClick = useCallback((e: React.MouseEvent) => {
    const currentTarget = e.currentTarget as HTMLElement;
    const bottomArea = currentTarget.getBoundingClientRect().bottom - 36 * 4;

    if (e.clientY > bottomArea && e.clientY < (bottomArea + 36)) {
      const lastBlock = editor.children[editor.children.length - 1] as SlateElement;
      const isEmptyLine = CustomEditor.getBlockTextContent(lastBlock) === '';
      const type = lastBlock.type;

      if (!lastBlock) return;
      if (isEmptyLine && type === BlockType.Paragraph) {
        editor.select(editor.end([editor.children.length - 1]));
        return;
      }

      CustomEditor.addBelowBlock(editor as YjsEditor, lastBlock.blockId as string, BlockType.Paragraph, {});
    }

  }, [editor]);

  const handleMouseDown = useCallback((e: React.MouseEvent) => {
    const detail = e.detail;

    if (detail >= 3) {
      e.stopPropagation();
      e.preventDefault();
    }
  }, []);

  const [linkOpen, setLinkOpen] = React.useState<Text | undefined>(undefined);
  const handleOpenLinkPopover = useCallback((text: Text) => {
    setLinkOpen(text);
  }, []);

  const handleCloseLinkPopover = useCallback(() => {
    setLinkOpen(undefined);
  }, []);

  return (
    <PanelProvider editor={editor}>
      <BlockPopoverProvider editor={editor}>
        <LeafContext.Provider value={{
          linkOpen,
          openLinkPopover: handleOpenLinkPopover,
          closeLinkPopover: handleCloseLinkPopover,
        }}>
          <Editable
            role={'textbox'}
            decorate={(entry: NodeEntry) => {
              const codeDecoration = codeDecorate?.(entry);
              const decoration = decorate(entry);

              return [...codeDecoration, ...decoration];
            }}
            id={`editor-${viewId}`}
            className={'outline-none custom-caret scroll-mb-[100px] scroll-mt-[300px] pb-36 min-w-0 max-w-full w-[988px] max-sm:px-6 px-24 focus:outline-none'}
            renderLeaf={Leaf}
            renderElement={renderElement}
            readOnly={readOnly}
            spellCheck={false}
            autoCorrect={'off'}
            autoComplete={'off'}
            onCompositionStart={onCompositionStart}
            onKeyDown={onKeyDown}
            onMouseDown={handleMouseDown}
            onClick={handleClick}
          />
          {!readOnly &&
            <Suspense>
              <EditorOverlay/>
              <HrefPopover
                open={!!linkOpen}
                onClose={handleCloseLinkPopover}
              />
            </Suspense>
          }

        </LeafContext.Provider>
      </BlockPopoverProvider>
    </PanelProvider>
  );
};

export default EditorEditable;
