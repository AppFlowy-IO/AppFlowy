import { YjsEditor } from '@/application/slate-yjs';
import { CustomEditor } from '@/application/slate-yjs/command';
import { CONTAINER_BLOCK_TYPES } from '@/application/slate-yjs/command/const';
import { findSlateEntryByBlockId } from '@/application/slate-yjs/utils/slateUtils';
import { BlockType } from '@/application/types';
import { getScrollParent } from '@/components/global-comment/utils';
import React, { useCallback, useEffect, useRef, useState } from 'react';
import { Editor, Element, Range, Transforms } from 'slate';
import { ReactEditor, useSlateStatic } from 'slate-react';
import { findEventNode, getBlockActionsPosition, getBlockCssProperty } from './utils';

export function useHoverControls ({ disabled, onAdded }: { disabled: boolean; onAdded: (blockId: string) => void; }) {
  const editor = useSlateStatic() as YjsEditor;
  const ref = useRef<HTMLDivElement>(null);
  const [hoveredBlockId, setHoveredBlockId] = useState<string | null>(null);
  const [cssProperty, setCssProperty] = useState<string>('');

  const recalculatePosition = useCallback(
    (blockElement: HTMLElement) => {
      const { top, left } = getBlockActionsPosition(editor, blockElement);

      const slateEditorDom = ReactEditor.toDOMNode(editor, editor);

      if (!ref.current) return;

      ref.current.style.top = `${top + slateEditorDom.offsetTop}px`;
      ref.current.style.left = `${left + slateEditorDom.offsetLeft - 64}px`;
    },
    [editor],
  );

  const close = useCallback(() => {
    const el = ref.current;

    if (!el) return;

    el.style.opacity = '0';
    el.style.pointerEvents = 'none';
    setHoveredBlockId(null);
    setCssProperty('');
  }, [ref]);

  useEffect(() => {
    const handleMouseMove = (e: MouseEvent) => {
      const el = ref.current;

      if (!el) return;

      let range: Range | null = null;
      let node: Element | null = null;

      try {
        range = ReactEditor.findEventRange(editor, e);
        if (!range) {
          throw new Error('No range found');
        }
      } catch {
        const editorDom = ReactEditor.toDOMNode(editor, editor);
        const rect = editorDom.getBoundingClientRect();
        const isOverLeftBoundary = e.clientX > rect.left;
        const isOverRightBoundary = e.clientX > rect.right - 96 && e.clientX < rect.right;
        let newX = e.clientX;

        if (isOverLeftBoundary || isOverRightBoundary) {
          newX = rect.left + editorDom.clientWidth / 2;
        }

        node = findEventNode(editor, {
          x: newX,
          y: e.clientY,
        });

      }

      if (!range && !node) {
        console.warn('No range and node found');
        return;
      } else if (range) {
        const match = editor.above({
          match: (n) => {
            return !Editor.isEditor(n) && Element.isElement(n) && n.blockId !== undefined;
          },
          at: range,
        });

        if (!match) {
          close();
          return;
        }

        node = match[0];
      }

      if (!node) {
        close();
        return;
      }

      const blockElement = ReactEditor.toDOMNode(editor, node);

      if (!blockElement) return;
      const tableElement = blockElement.closest('[data-block-type="table"]') as HTMLElement;

      if (tableElement) {
        recalculatePosition(tableElement);
        el.style.opacity = '1';
        el.style.pointerEvents = 'auto';
        const tableNode = ReactEditor.toSlateNode(editor, tableElement) as Element;

        setCssProperty(getBlockCssProperty(tableNode));
        setHoveredBlockId(tableNode.blockId as string);
      } else {
        recalculatePosition(blockElement);
        el.style.opacity = '1';
        el.style.pointerEvents = 'auto';

        setCssProperty(getBlockCssProperty(node));
        setHoveredBlockId(node.blockId as string);
      }

    };

    const dom = ReactEditor.toDOMNode(editor, editor);

    if (!disabled) {
      dom.addEventListener('mousemove', handleMouseMove);
      dom.parentElement?.addEventListener('mouseleave', close);
      getScrollParent(dom)?.addEventListener('scroll', close);
    }

    return () => {
      dom.removeEventListener('mousemove', handleMouseMove);
      dom.parentElement?.removeEventListener('mouseleave', close);
      getScrollParent(dom)?.removeEventListener('scroll', close);
    };
  }, [close, editor, ref, recalculatePosition, disabled]);

  useEffect(() => {
    let observer: MutationObserver | null = null;

    if (hoveredBlockId) {
      const [node] = findSlateEntryByBlockId(editor, hoveredBlockId);
      const dom = ReactEditor.toDOMNode(editor, node);

      if (dom.parentElement) {
        observer = new MutationObserver(close);

        observer.observe(dom.parentElement, {
          childList: true,
        });
      }
    }

    return () => {
      observer?.disconnect();
    };
  }, [close, editor, hoveredBlockId]);

  const onClickAdd = useCallback((e: React.MouseEvent) => {
    e.preventDefault();
    if (!hoveredBlockId) return;
    const [node, path] = findSlateEntryByBlockId(editor, hoveredBlockId);
    const start = editor.start(path);

    ReactEditor.focus(editor);
    Transforms.select(editor, start);

    const type = node.type as BlockType;

    if (CustomEditor.getBlockTextContent(node, 2) === '' && [...CONTAINER_BLOCK_TYPES, BlockType.HeadingBlock].includes(type)) {
      onAdded(hoveredBlockId);
      return;
    }

    let newBlockId: string | undefined = '';

    if (e.altKey) {
      newBlockId = CustomEditor.addAboveBlock(editor, hoveredBlockId, BlockType.Paragraph, {});
    } else {
      newBlockId = CustomEditor.addBelowBlock(editor, hoveredBlockId, BlockType.Paragraph, {});
    }

    onAdded(newBlockId || '');
  }, [editor, hoveredBlockId, onAdded]);

  return {
    hoveredBlockId,
    ref,
    cssProperty,
    onClickAdd,
  };
}