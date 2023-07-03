import React, { useCallback, useEffect, useMemo, useRef } from 'react';
import { TemporaryType } from '$app/interfaces/document';
import TemporaryEquation from '$app/components/document/_shared/TemporaryInput/TemporaryEquation';
import { useSubscribeTemporary } from '$app/components/document/_shared/SubscribeTemporary.hooks';
import { isOverlappingPrefix } from '$app/utils/document/temporary';
import { PopoverPosition } from '@mui/material';
import { useAppDispatch } from '$app/stores/store';
import { temporaryActions } from '$app_reducers/document/temporary_slice';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';

function TemporaryInput({ leaf, children }: { leaf: { text: string }; children: React.ReactNode }) {
  const temporaryState = useSubscribeTemporary();
  const id = temporaryState?.id;
  const dispatch = useAppDispatch();
  const ref = useRef<HTMLSpanElement>(null);
  const { docId } = useSubscribeDocument();
  const match = useMemo(() => {
    if (!leaf.text) return false;
    if (!temporaryState) return false;
    const { selectedText, type } = temporaryState;

    switch (type) {
      case TemporaryType.Equation:
        // when the leaf is split, the placeholder is not the same as the leaf text,
        // so we can only check for overlapping prefix and hidden other leafs
        return leaf.text === selectedText || isOverlappingPrefix(leaf.text, selectedText);
      default:
        return false;
    }
  }, [temporaryState, leaf.text]);

  const renderPlaceholder = useCallback(() => {
    if (!temporaryState) return null;
    const { type, data } = temporaryState;

    switch (type) {
      case TemporaryType.Equation:
        return <TemporaryEquation latex={data.latex} />;
      default:
        return null;
    }
  }, [temporaryState]);

  const setAnchorPosition = useCallback(
    (position: PopoverPosition | null) => {
      dispatch(
        temporaryActions.updateTemporaryState({
          id: docId,
          state: {
            id,
            popoverPosition: position,
          },
        })
      );
    },
    [dispatch, docId, id]
  );

  useEffect(() => {
    if (!ref.current || !match) return;
    const { width, height, top, left } = ref.current.getBoundingClientRect();

    setAnchorPosition({
      top: top + height,
      left: left + width / 2,
    });
  }, [dispatch, docId, id, match, setAnchorPosition]);

  return (
    <span ref={ref}>
      {match ? renderPlaceholder() : null}
      <span className={'absolute opacity-0'}>{children}</span>
    </span>
  );
}

export default TemporaryInput;
