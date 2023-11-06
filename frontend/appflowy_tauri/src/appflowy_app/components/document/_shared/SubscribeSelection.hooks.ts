import { useAppSelector } from '$app/stores/store';
import { RangeState, RangeStatic } from '$app/interfaces/document';
import { useMemo, useRef } from 'react';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';
import { RANGE_NAME, TEMPORARY_NAME } from '$app/constants/document/name';

export function useSubscribeDecorate(id: string) {
  const { docId } = useSubscribeDocument();

  const decorateSelection = useAppSelector((state) => {
    return state[RANGE_NAME][docId]?.ranges[id];
  });

  const temporarySelection = useAppSelector((state) => {
    const temporary = state[TEMPORARY_NAME][docId];

    if (!temporary || temporary.id !== id) return;
    return temporary.selection;
  });

  return {
    decorateSelection,
    temporarySelection,
  };
}

export function useFocused(id: string) {
  const { docId } = useSubscribeDocument();

  const caretRef = useRef<RangeStatic>();
  const focusCaret = useAppSelector((state) => {
    const currentCaret = state[RANGE_NAME][docId]?.caret;

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
  const { docId } = useSubscribeDocument();

  const rangeRef = useRef<RangeState>();

  useAppSelector((state) => {
    const currentRange = state[RANGE_NAME][docId];

    rangeRef.current = currentRange;
  });
  return rangeRef;
}

export function useSubscribeRanges() {
  const { docId } = useSubscribeDocument();

  const rangeState = useAppSelector((state) => {
    return state[RANGE_NAME][docId];
  });

  return rangeState;
}

export function useSubscribeCaret() {
  const { docId } = useSubscribeDocument();

  const caret = useAppSelector((state) => {
    return state[RANGE_NAME][docId]?.caret;
  });

  return caret;
}
