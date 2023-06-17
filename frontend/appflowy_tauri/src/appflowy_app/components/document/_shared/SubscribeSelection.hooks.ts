import { useAppSelector } from '$app/stores/store';
import { RangeState, RangeStatic } from '$app/interfaces/document';
import { useMemo, useRef } from 'react';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';

export function useSubscribeDecorate(id: string) {
  const { docId } = useSubscribeDocument();

  const decorateSelection = useAppSelector((state) => {
    return state.documentRange[docId]?.ranges[id];
  });

  const linkDecorateSelection = useAppSelector((state) => {
    const linkPopoverState = state.documentLinkPopover[docId];
    if (!linkPopoverState?.open || linkPopoverState?.id !== id) return;
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
  const { docId } = useSubscribeDocument();

  const caretRef = useRef<RangeStatic>();
  const focusCaret = useAppSelector((state) => {
    const currentCaret = state.documentRange[docId]?.caret;
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
  const { docId, controller } = useSubscribeDocument();

  const rangeRef = useRef<RangeState>();
  useAppSelector((state) => {
    const currentRange = state.documentRange[docId];
    rangeRef.current = currentRange;
  });
  return rangeRef;
}

export function useSubscribeRanges() {
  const { docId } = useSubscribeDocument();

  const rangeState = useAppSelector((state) => {
    return state.documentRange[docId];
  });

  return rangeState;
}

export function useSubscribeCaret() {
  const { docId } = useSubscribeDocument();

  const caret = useAppSelector((state) => {
    return state.documentRange[docId]?.caret;
  });

  return caret;
}
