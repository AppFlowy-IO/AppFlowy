import { YjsEditor } from '@/application/slate-yjs';
import { CustomEditor } from '@/application/slate-yjs/command';
import { findSlateEntryByBlockId } from '@/application/slate-yjs/utils/slateUtils';
import { BlockType } from '@/application/types';
import React, { useCallback, useEffect, useRef, useState } from 'react';
import { Editor, Element, Range } from 'slate';
import { ReactEditor, useSlateStatic } from 'slate-react';
import { findEventNode, getBlockActionsPosition, getBlockCssProperty } from './utils';

export function useHoverControls ({ disabled }: { disabled: boolean }) {
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
      console.log('handleMouseMove');
      const el = ref.current;

      if (!el) return;

      const target = e.target as HTMLElement;

      if (target.closest(`[contenteditable="false"]`)) {
        return;
      }

      let range: Range | null = null;
      let node: Element | null = null;

      try {
        range = ReactEditor.findEventRange(editor, e);
      } catch {
        const editorDom = ReactEditor.toDOMNode(editor, editor);
        const rect = editorDom.getBoundingClientRect();
        const isOverLeftBoundary = e.clientX < rect.left + 64;
        const isOverRightBoundary = e.clientX > rect.right - 64;
        let newX = e.clientX;

        if (isOverLeftBoundary) {
          newX = rect.left + 64;
        }

        if (isOverRightBoundary) {
          newX = rect.right - 64;
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
      recalculatePosition(blockElement);
      el.style.opacity = '1';
      el.style.pointerEvents = 'auto';

      setCssProperty(getBlockCssProperty(node));
      setHoveredBlockId(node.blockId as string);
    };

    const dom = ReactEditor.toDOMNode(editor, editor);

    if (!disabled) {
      dom.addEventListener('mousemove', handleMouseMove);
      dom.parentElement?.addEventListener('mouseleave', close);
    }

    return () => {
      dom.removeEventListener('mousemove', handleMouseMove);
      dom.parentElement?.removeEventListener('mouseleave', close);
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
    e.stopPropagation();
    if (!hoveredBlockId) return;

    if (e.altKey) {
      CustomEditor.addAboveBlock(editor, hoveredBlockId, BlockType.Paragraph, {});
    } else {
      CustomEditor.addBelowBlock(editor, hoveredBlockId, BlockType.Paragraph, {});
    }
  }, [editor, hoveredBlockId]);

  return {
    hoveredBlockId,
    ref,
    cssProperty,
    onClickAdd,
  };
}