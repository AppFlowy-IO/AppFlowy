import React, { useCallback, useEffect, useRef, useState } from 'react';
import { RangeStaticNoId, TemporaryType } from '$app/interfaces/document';
import TemporaryEquation from '$app/components/document/_shared/TemporaryInput/TemporaryEquation';
import { useSubscribeTemporary } from '$app/components/document/_shared/SubscribeTemporary.hooks';
import { PopoverPosition } from '@mui/material';
import { useAppDispatch } from '$app/stores/store';
import { temporaryActions } from '$app_reducers/document/temporary_slice';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';
import TemporaryLink from '$app/components/document/_shared/TemporaryInput/TemporaryLink';

function TemporaryInput({
  leaf,
  children,
  getSelection,
}: {
  leaf: { text: string };
  children: React.ReactNode;
  getSelection: (node: Element) => RangeStaticNoId | null;
}) {
  const temporaryState = useSubscribeTemporary();
  const id = temporaryState?.id;
  const dispatch = useAppDispatch();
  const ref = useRef<HTMLSpanElement>(null);
  const { docId } = useSubscribeDocument();
  const [match, setMatch] = useState(false);

  const getMatch = useCallback(() => {
    if (!ref.current) return false;
    if (!leaf.text) return false;
    if (!temporaryState) return false;
    const { selectedText } = temporaryState;
    const selection = getSelection(ref.current);

    if (!selection) return false;

    return leaf.text === selectedText || selection.index <= temporaryState.selection.index;
  }, [leaf.text, temporaryState, getSelection]);

  const renderPlaceholder = useCallback(() => {
    if (!temporaryState) return null;
    const { type, data } = temporaryState;

    switch (type) {
      case TemporaryType.Equation:
        return <TemporaryEquation latex={data.latex || ''} />;
      case TemporaryType.Link:
        return <TemporaryLink {...data} />;
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

  useEffect(() => {
    const match = getMatch();
    setMatch(match);
  }, [getMatch]);

  return (
    <span ref={ref}>
      {match ? renderPlaceholder() : null}
      <span className={`absolute opacity-0 ${match ? 'w-0' : ''}`}>{children}</span>
    </span>
  );
}

export default TemporaryInput;
