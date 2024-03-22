import { RefObject, useCallback, useEffect, useState } from 'react';
import { ReactEditor, useSlate } from 'slate-react';
import { findEventNode, getBlockActionsPosition } from '$app/components/editor/components/tools/block_actions/utils';
import { Element, Editor, Range } from 'slate';
import { EditorNodeType } from '$app/application/document/document.types';
import { Log } from '$app/utils/log';

export function useBlockActionsToolbar(ref: RefObject<HTMLDivElement>, contextMenuVisible: boolean) {
  const editor = useSlate();
  const [node, setNode] = useState<Element | null>(null);

  const recalculatePosition = useCallback(
    (blockElement: HTMLElement) => {
      const { top, left } = getBlockActionsPosition(editor, blockElement);

      const slateEditorDom = ReactEditor.toDOMNode(editor, editor);

      if (!ref.current) return;

      ref.current.style.top = `${top + slateEditorDom.offsetTop}px`;
      ref.current.style.left = `${left + slateEditorDom.offsetLeft - 64}px`;
    },
    [editor, ref]
  );

  const close = useCallback(() => {
    const el = ref.current;

    if (!el) return;

    el.style.opacity = '0';
    el.style.pointerEvents = 'none';
    setNode(null);
  }, [ref]);

  useEffect(() => {
    const handleMouseMove = (e: MouseEvent) => {
      const el = ref.current;

      if (!el) return;

      const target = e.target as HTMLElement;

      if (target.closest(`[contenteditable="false"]`)) {
        return;
      }

      let range: Range | null = null;
      let node;

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
        Log.warn('No range and node found');
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

        node = match[0] as Element;
      }

      if (!node) {
        close();
        return;
      }

      if (node.type === EditorNodeType.Page) return;
      const blockElement = ReactEditor.toDOMNode(editor, node);

      if (!blockElement) return;
      recalculatePosition(blockElement);
      el.style.opacity = '1';
      el.style.pointerEvents = 'auto';
      const slateNode = ReactEditor.toSlateNode(editor, blockElement) as Element;

      setNode(slateNode);
    };

    const dom = ReactEditor.toDOMNode(editor, editor);

    if (!contextMenuVisible) {
      dom.addEventListener('mousemove', handleMouseMove);
      dom.parentElement?.addEventListener('mouseleave', close);
    }

    return () => {
      dom.removeEventListener('mousemove', handleMouseMove);
      dom.parentElement?.removeEventListener('mouseleave', close);
    };
  }, [close, editor, contextMenuVisible, ref, recalculatePosition]);

  useEffect(() => {
    let observer: MutationObserver | null = null;

    if (node) {
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
  }, [close, editor, node]);

  return {
    node: node?.type === EditorNodeType.Page ? null : node,
  };
}
