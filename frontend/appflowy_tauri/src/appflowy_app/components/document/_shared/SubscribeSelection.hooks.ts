import { useAppSelector } from '$app/stores/store';
import { RangeState, RangeStatic } from '$app/interfaces/document';
import { useMemo, useRef } from 'react';

export function useSubscribeDecorate(id: string) {
  const decorateSelection = useAppSelector((state) => {
    return state.documentRange.ranges[id];
  });

  const linkDecorateSelection = useAppSelector((state) => {
    const linkPopoverState = state.documentLinkPopover;
    if (!linkPopoverState.open || linkPopoverState.id !== id) return;
    return {
      selection: linkPopoverState.selection,
      placeholder: linkPopoverState.title,
    };
  });

  return {
    decorateSelection,
    linkDecorateSelection,
  };
}
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

  const focused = useMemo(() => {
    return focusCaret && focusCaret?.id === id;
  }, [focusCaret, id]);

  return {
    focused,
    caretRef,
    focusCaret,
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
