import { useAppSelector } from '$app/stores/store';
import { RangeState, RangeStatic } from '$app/interfaces/document';
import { useMemo, useRef } from 'react';

export function useFocused(id: string) {
  const caretRef = useRef<RangeStatic>();
  const focusCaret = useAppSelector((state) => {
    const currentCaret = state.documentRange.caret;
    caretRef.current = currentCaret;
    if (currentCaret?.id === id) {
      return currentCaret;
    }
    return null;
  });

  const lastSelection = useAppSelector((state) => {
    return state.documentRange.ranges[id];
  });

  const focused = useMemo(() => {
    return focusCaret && focusCaret?.id === id;
  }, [focusCaret, id]);

  const memoizedLastSelection = useMemo(() => {
    return lastSelection;
  }, [JSON.stringify(lastSelection)]);

  return {
    focused,
    caretRef,
    focusCaret,
    lastSelection: memoizedLastSelection,
  };
}

export function useRangeRef() {
  const rangeRef = useRef<RangeState>();
  useAppSelector((state) => {
    const currentRange = state.documentRange;
    rangeRef.current = currentRange;
  });
  return rangeRef;
}
