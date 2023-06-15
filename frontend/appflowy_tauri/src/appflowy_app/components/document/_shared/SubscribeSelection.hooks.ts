import { useAppSelector } from '$app/stores/store';
import { RangeState, RangeStatic } from '$app/interfaces/document';
import { useContext, useMemo, useRef } from 'react';
import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';

export function useSubscribeDecorate(id: string) {
  const controller = useContext(DocumentControllerContext);
  const docId = controller?.documentId;
  const decorateSelection = useAppSelector((state) => {
    return state.documentRange[docId].ranges[id];
  });

  const linkDecorateSelection = useAppSelector((state) => {
    const linkPopoverState = state.documentLinkPopover[docId];
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
  const controller = useContext(DocumentControllerContext);
  const docId = controller?.documentId;
  const caretRef = useRef<RangeStatic>();
  const focusCaret = useAppSelector((state) => {
    const currentCaret = state.documentRange[docId].caret;
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
  const controller = useContext(DocumentControllerContext);
  const docId = controller?.documentId;
  const rangeRef = useRef<RangeState>();
  useAppSelector((state) => {
    const currentRange = state.documentRange[docId];
    rangeRef.current = currentRange;
  });
  return rangeRef;
}
