import { useEffect, useState } from 'react';
import { ReactEditor, useSlate } from 'slate-react';
import { getBlockActionsPosition } from '$app/components/editor/components/tools/block_actions/utils';
import { Element, Editor } from 'slate';
import { EditorNodeType } from '$app/application/document/document.types';

export function useBlockActionsToolbar(ref: React.RefObject<HTMLDivElement>) {
  const editor = useSlate();
  const [node, setNode] = useState<Element | null>(null);

  useEffect(() => {
    const handleMouseMove = (e: MouseEvent) => {
      const el = ref.current;

      if (!el) return;

      const target = e.target as HTMLElement;

      if (target.closest(`[contenteditable="false"]`)) {
        return;
      }

      const range = ReactEditor.findEventRange(editor, e);

      if (!range) return;
      const match = editor.above({
        match: (n) => {
          return !Editor.isEditor(n) && Element.isElement(n) && n.blockId !== undefined;
        },
        at: range,
      });

      if (!match) {
        el.style.opacity = '0';
        el.style.pointerEvents = 'none';
        setNode(null);
        return;
      }

      const node = match[0] as Element;

      if (node.type === EditorNodeType.Page) return;
      const blockElement = ReactEditor.toDOMNode(editor, node);

      if (!blockElement) return;

      const { top, left } = getBlockActionsPosition(editor, blockElement);

      const slateEditorDom = ReactEditor.toDOMNode(editor, editor);

      el.style.opacity = '1';
      el.style.pointerEvents = 'auto';
      el.style.top = `${top + slateEditorDom.offsetTop}px`;
      el.style.left = `${left + slateEditorDom.offsetLeft - 64}px`;
      const slateNode = ReactEditor.toSlateNode(editor, blockElement) as Element;

      setNode(slateNode);
    };

    const handleMouseLeave = (_e: MouseEvent) => {
      const el = ref.current;

      if (!el) return;

      el.style.opacity = '0';
      el.style.pointerEvents = 'none';
      setNode(null);
    };

    const dom = ReactEditor.toDOMNode(editor, editor);

    dom.addEventListener('mousemove', handleMouseMove);
    dom.parentElement?.addEventListener('mouseleave', handleMouseLeave);
    return () => {
      dom.removeEventListener('mousemove', handleMouseMove);
      dom.parentElement?.removeEventListener('mouseleave', handleMouseLeave);
    };
  }, [editor, ref]);

  return {
    node: node?.type === EditorNodeType.Page ? null : node,
  };
}
