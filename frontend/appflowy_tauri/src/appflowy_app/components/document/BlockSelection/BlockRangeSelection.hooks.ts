import { useCallback, useEffect, useRef, useState } from 'react';
import { rangeActions } from '$app_reducers/document/slice';
import { useAppDispatch } from '$app/stores/store';
import {
  getBlockIdByPoint,
  getNodeTextBoxByBlockId,
  isFocused,
  setCursorAtEndOfNode,
  setCursorAtStartOfNode,
} from '$app/utils/document/node';
import { useRangeKeyDown } from '$app/components/document/BlockSelection/RangeKeyDown.hooks';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';
import { useSubscribeRanges } from '$app/components/document/_shared/SubscribeSelection.hooks';

export function useBlockRangeSelection(container: HTMLDivElement) {
  const dispatch = useAppDispatch();
  const onKeyDown = useRangeKeyDown();
  const { docId } = useSubscribeDocument();

  const range = useSubscribeRanges();
  const isDragging = range?.isDragging;

  const anchorRef = useRef<{
    id: string;
    point: { x: number; y: number };
  } | null>(null);

  const [focus, setFocus] = useState<{
    id: string;
    point: { x: number; y: number };
  } | null>(null);

  const [isForward, setForward] = useState(true);

  // display caret color
  useEffect(() => {
    if (!range) return;
    const { anchor, focus } = range;
    if (!anchor || !focus) {
      container.classList.remove('caret-transparent');
      return;
    }
    // if the focus block is different from the anchor block, we need to set the caret transparent
    if (focus.id !== anchor.id) {
      container.classList.add('caret-transparent');
    } else {
      container.classList.remove('caret-transparent');
    }
  }, [container.classList, range]);

  useEffect(() => {
    const anchor = anchorRef.current;
    if (!anchor || !focus) return;
    const selection = window.getSelection();
    if (!selection) return;
    // update focus point
    dispatch(
      rangeActions.setFocusPoint({
        ...focus,
        docId,
      })
    );

    const focused = isFocused(focus.id);
    // if the focus block is not focused, we need to set the cursor position
    if (!focused) {
      // if the focus block is the same as the anchor block, we just update the anchor's range
      if (anchor.id === focus.id) {
        const range = document.caretRangeFromPoint(
          anchor.point.x - container.scrollLeft,
          anchor.point.y - container.scrollTop
        );
        if (!range) return;
        const selection = window.getSelection();
        selection?.removeAllRanges();
        selection?.addRange(range);
        return;
      }

      const node = getNodeTextBoxByBlockId(focus.id);
      if (!node) return;
      // if the selection is forward, we set the cursor position to the start of the focus block
      if (isForward) {
        setCursorAtStartOfNode(node);
      } else {
        // if the selection is backward, we set the cursor position to the end of the focus block
        setCursorAtEndOfNode(node);
      }
    }
  }, [container, dispatch, docId, focus, isForward]);

  const handleDragStart = useCallback(
    (e: MouseEvent) => {
      setForward(true);
      // skip if the target is not a block
      const blockId = getBlockIdByPoint(e.target as HTMLElement);
      if (!blockId) {
        dispatch(rangeActions.initialState(docId));
        return;
      }
      dispatch(rangeActions.clearRanges({ docId, exclude: blockId }));
      const startX = e.clientX + container.scrollLeft;
      const startY = e.clientY + container.scrollTop;

      const anchor = {
        id: blockId,
        point: {
          x: startX,
          y: startY,
        },
      };

      anchorRef.current = {
        ...anchor,
      };
      // set the anchor point and focus point
      dispatch(rangeActions.setAnchorPoint({ ...anchor, docId }));
      dispatch(rangeActions.setFocusPoint({ ...anchor, docId }));
      dispatch(
        rangeActions.setDragging({
          isDragging: true,
          docId,
        })
      );
      return;
    },
    [container.scrollLeft, container.scrollTop, dispatch, docId]
  );

  const handleDraging = useCallback(
    (e: MouseEvent) => {
      if (!isDragging || !anchorRef.current) return;

      // skip if the target is not a block
      const blockId = getBlockIdByPoint(e.target as HTMLElement);
      if (!blockId) {
        return;
      }

      const endX = e.clientX + container.scrollLeft;
      const endY = e.clientY + container.scrollTop;
      // set the focus point
      setFocus({
        id: blockId,
        point: {
          x: endX,
          y: endY,
        },
      });
      // set forward
      const anchorId = anchorRef.current.id;
      if (anchorId === blockId) {
        const startX = anchorRef.current.point.x;
        setForward(startX < endX);
        return;
      }
      const startY = anchorRef.current.point.y;
      setForward(startY < endY);
    },
    [container.scrollLeft, container.scrollTop, isDragging]
  );

  const handleDragEnd = useCallback(() => {
    if (!isDragging) return;
    setFocus(null);
    anchorRef.current = null;
    dispatch(
      rangeActions.setDragging({
        isDragging: false,
        docId,
      })
    );
  }, [docId, dispatch, isDragging]);

  useEffect(() => {
    document.addEventListener('mousedown', handleDragStart);
    document.addEventListener('mousemove', handleDraging);
    document.addEventListener('mouseup', handleDragEnd);
    container.addEventListener('keydown', onKeyDown, true);
    return () => {
      document.removeEventListener('mousedown', handleDragStart);
      document.removeEventListener('mousemove', handleDraging);
      document.removeEventListener('mouseup', handleDragEnd);

      container.removeEventListener('keydown', onKeyDown, true);
    };
  }, [handleDragStart, handleDragEnd, handleDraging, container, onKeyDown]);

  return null;
}
