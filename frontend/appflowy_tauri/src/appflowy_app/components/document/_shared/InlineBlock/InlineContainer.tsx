import React, { useCallback, useContext, useEffect, useRef } from 'react';
import './inline.css';
import { NodeIdContext } from '$app/components/document/_shared/SubscribeNode.hooks';
import { useFocused, useRangeRef } from '$app/components/document/_shared/SubscribeSelection.hooks';
import { RangeStaticNoId, TemporaryType } from '$app/interfaces/document';
import { useAppDispatch } from '$app/stores/store';
import { createTemporary } from '$app_reducers/document/async-actions/temporary';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';
import KatexMath from '$app/components/document/_shared/KatexMath';

const LEFT_CARET_CLASS = 'inline-block-with-cursor-left';
const RIGHT_CARET_CLASS = 'inline-block-with-cursor-right';

function InlineContainer({
  isFirst,
  isLast,
  children,
  getSelection,
  selectedText,
  data,
  temporaryType,
}: {
  getSelection: (node: Element) => RangeStaticNoId | null;
  children: React.ReactNode;
  formula: string;
  selectedText: string;
  isLast: boolean;
  isFirst: boolean;
  data: {
    latex?: string;
  };
  temporaryType: TemporaryType;
}) {
  const id = useContext(NodeIdContext);
  const { docId } = useSubscribeDocument();
  const { focused, focusCaret } = useFocused(id);
  const rangeRef = useRangeRef();
  const ref = useRef<HTMLSpanElement>(null);
  const dispatch = useAppDispatch();
  const onClick = useCallback(
    (node: HTMLSpanElement) => {
      const selection = getSelection(node);

      if (!selection) return;
      const temporaryData = temporaryType === TemporaryType.Equation ? { latex: data.latex } : {};

      dispatch(
        createTemporary({
          docId,
          state: {
            id,
            selection,
            selectedText,
            type: temporaryType,
            data: temporaryData as { latex: string },
          },
        })
      );
    },
    [getSelection, temporaryType, data.latex, dispatch, docId, id, selectedText]
  );

  const renderNode = useCallback(() => {
    switch (temporaryType) {
      case TemporaryType.Equation:
        return <KatexMath latex={data.latex!} isInline />;
      default:
        return null;
    }
  }, [data, temporaryType]);

  const resetCaret = useCallback(() => {
    if (!ref.current) return;
    ref.current.classList.remove(RIGHT_CARET_CLASS);
    ref.current.classList.remove(LEFT_CARET_CLASS);
  }, []);

  useEffect(() => {
    resetCaret();
    if (!ref.current) return;
    if (!focused || !focusCaret || rangeRef.current?.isDragging) {
      return;
    }

    const inlineBlockSelection = getSelection(ref.current);

    if (!inlineBlockSelection) return;
    const distance = inlineBlockSelection.index - focusCaret.index;

    if (distance === 0 && isFirst) {
      ref.current.classList.add(LEFT_CARET_CLASS);
      return;
    }

    if (distance === -1) {
      ref.current.classList.add(RIGHT_CARET_CLASS);
      return;
    }
  }, [focused, focusCaret, getSelection, resetCaret, isFirst, rangeRef]);

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

  if (!selectedText) return null;

  return (
    <span className={'inline-block-with-cursor relative'} ref={ref} onClick={() => onClick(ref.current!)}>
      <span
        style={{
          pointerEvents: 'none',
        }}
        className={`absolute caret-transparent opacity-0`}
      >
        {children}
      </span>
      <span
        data-slate-placeholder={true}
        contentEditable={false}
        style={{
          pointerEvents: 'none',
        }}
      >
        {renderNode()}
      </span>
      {isLast && <span data-slate-string={false}>&#xFEFF;</span>}
    </span>
  );
}

export default InlineContainer;
