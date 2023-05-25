import { useCallback, useEffect, useRef, useState } from 'react';
import { getBlockIdByPoint } from '$app/utils/document/blocks/selection';
import { rangeSelectionActions } from '$app_reducers/document/slice';
import { useAppDispatch } from '$app/stores/store';
import { getNodesInRange } from '$app/utils/document/blocks/common';
import { setRangeSelectionThunk } from '$app_reducers/document/async-actions/range_selection';

export function useBlockRangeSelection(container: HTMLDivElement) {
  const dispatch = useAppDispatch();
  const anchorRef = useRef<{
    id: string;
    point: { x: number; y: number };
    range?: Range;
  } | null>(null);

  const [isDragging, setDragging] = useState(false);

  const reset = useCallback(() => {
    dispatch(rangeSelectionActions.clearRange());
  }, [dispatch]);

  useEffect(() => {
    dispatch(rangeSelectionActions.setDragging(isDragging));
  }, [dispatch, isDragging]);

  const handleDragStart = useCallback(
    (e: MouseEvent) => {
      reset();
      const blockId = getBlockIdByPoint(e.target as HTMLElement);
      if (!blockId) {
        return;
      }

      const startX = e.clientX + container.scrollLeft;
      const startY = e.clientY + container.scrollTop;
      anchorRef.current = {
        id: blockId,
        point: {
          x: startX,
          y: startY,
        },
      };
      setDragging(true);
    },
    [container.scrollLeft, container.scrollTop, reset]
  );

  const handleDraging = useCallback(
    (e: MouseEvent) => {
      if (!isDragging || !anchorRef.current) return;

      const blockId = getBlockIdByPoint(e.target as HTMLElement);
      if (!blockId) {
        return;
      }

      const anchorId = anchorRef.current.id;
      if (anchorId === blockId) {
        const endX = e.clientX + container.scrollTop;
        const isForward = endX > anchorRef.current.point.x;
        dispatch(rangeSelectionActions.setForward(isForward));
        return;
      }

      const endY = e.clientY + container.scrollTop;
      const isForward = endY > anchorRef.current.point.y;
      dispatch(rangeSelectionActions.setForward(isForward));
    },
    [container.scrollTop, dispatch, isDragging]
  );

  const handleDragEnd = useCallback(() => {
    if (!isDragging) return;
    setDragging(false);
    dispatch(setRangeSelectionThunk());
  }, [dispatch, isDragging]);

  // TODO: This is a hack to fix the issue that the selection is lost when scrolling
  const handleScroll = useCallback(() => {
    if (isDragging || !anchorRef.current) return;
    const selection = window.getSelection();
    if (!selection?.rangeCount && anchorRef.current.range) {
      selection?.addRange(anchorRef.current.range);
    } else {
      anchorRef.current.range = selection?.getRangeAt(0);
    }
  }, [isDragging]);

  useEffect(() => {
    document.addEventListener('mousedown', handleDragStart);
    document.addEventListener('mousemove', handleDraging, true);
    document.addEventListener('mouseup', handleDragEnd);
    container.addEventListener('scroll', handleScroll);

    return () => {
      document.removeEventListener('mousedown', handleDragStart);
      document.removeEventListener('mousemove', handleDraging, true);
      document.removeEventListener('mouseup', handleDragEnd);
      container.removeEventListener('scroll', handleScroll);
    };
  }, [handleDragStart, handleDragEnd, handleDraging, container, handleScroll]);

  return null;
}
