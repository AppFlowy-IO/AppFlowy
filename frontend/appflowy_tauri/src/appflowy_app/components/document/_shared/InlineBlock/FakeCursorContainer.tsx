import React, { useContext, useEffect, useRef, useState } from 'react';
import { useFocused, useRangeRef } from '$app/components/document/_shared/SubscribeSelection.hooks';
import { NodeIdContext } from '$app/components/document/_shared/SubscribeNode.hooks';

/**
 * This component is used to wrap the cursor display position for inline block.
 * Since the children of inline blocks are just single characters,
 * if not wrapped, the cursor position would follow the character instead of the block's boundary.
 * This component ensures that when the cursor switches between characters,
 * it is wrapped to move within the block's boundary.
 */
export const FakeCursorContainer = ({
  isFirst,
  isLast,
  onClick,
  getSelection,
  children,
  renderNode,
}: {
  onClick?: (node: HTMLSpanElement) => void;
  getSelection: (element: HTMLElement) => { index: number; length: number } | null;
  isFirst: boolean;
  isLast: boolean;
  children: React.ReactNode;
  renderNode: () => React.ReactNode;
}) => {
  const id = useContext(NodeIdContext);
  const ref = useRef<HTMLSpanElement>(null);
  const { focused, focusCaret } = useFocused(id);
  const rangeRef = useRangeRef();
  const [position, setPosition] = useState<'left' | 'right' | undefined>();

  useEffect(() => {
    setPosition(undefined);
    if (!ref.current) return;
    if (!focused || !focusCaret || rangeRef.current?.isDragging) {
      return;
    }

    const inlineBlockSelection = getSelection(ref.current);

    if (!inlineBlockSelection) return;
    const distance = inlineBlockSelection.index - focusCaret.index;

    if (distance === 0 && isFirst) {
      setPosition('left');
      return;
    }

    if (distance === -1) {
      setPosition('right');
      return;
    }
  }, [focused, focusCaret, getSelection, isFirst, rangeRef]);

  useEffect(() => {
    if (!ref.current) return;
    const onMouseDown = (e: MouseEvent) => {
      if (e.target === ref.current) {
        e.stopPropagation();
        e.preventDefault();
      }
    };

    // prevent page scroll when the caret change by mouse down
    document.addEventListener('mousedown', onMouseDown, true);
    return () => {
      document.removeEventListener('mousedown', onMouseDown, true);
    };
  }, []);

  return (
    <span className={'relative inline-block px-1'} ref={ref} onClick={() => ref.current && onClick?.(ref.current)}>
      <span
        style={{
          pointerEvents: 'none',
          left: position === 'left' ? '-1px' : undefined,
          right: position === 'right' ? '-1px' : undefined,
          caretColor: position === undefined ? 'transparent' : undefined,
        }}
        className={`absolute text-transparent`}
      >
        {children}
      </span>
      <span data-slate-placeholder={true} contentEditable={false} className={'inline-block-content'}>
        {renderNode()}
      </span>
      {isLast && <span data-slate-string={false}>&#xFEFF;</span>}
    </span>
  );
};
