import { useEffect, useState } from 'react';
import { ReactEditor, useSlate } from 'slate-react';
import { getBlockActionsPosition } from '$app/components/editor/components/tools/block_actions/utils';
import { Element } from 'slate';

export function useBlockActionsToolbar(ref: React.RefObject<HTMLDivElement>) {
  const editor = useSlate();
  const [node, setNode] = useState<Element | null>(null);

  useEffect(() => {
    const handleMouseMove = (e: MouseEvent) => {
      const el = ref.current;

      if (!el) return;

      const target = e.target as HTMLElement;

      if (target.closest('.block-actions')) return;
      const blockElement = target ? (target.closest('.block-element') as HTMLElement) : null;

      if (!blockElement) {
        el.style.opacity = '0';
        el.style.pointerEvents = 'none';
        setNode(null);
        return;
      }

      const { top, left } = getBlockActionsPosition(editor, blockElement);

      const slateEditorDom = ReactEditor.toDOMNode(editor, editor);

      el.style.opacity = '1';
      el.style.pointerEvents = 'auto';
      el.style.top = `${top + slateEditorDom.offsetTop}px`;
      el.style.left = `${left + slateEditorDom.offsetLeft}px`;
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

    document.addEventListener('mousemove', handleMouseMove);
    document.addEventListener('mouseleave', handleMouseLeave);
    return () => {
      document.removeEventListener('mousemove', handleMouseMove);
      document.removeEventListener('mouseleave', handleMouseLeave);
    };
  }, [editor, ref]);

  return {
    node,
  };
}
