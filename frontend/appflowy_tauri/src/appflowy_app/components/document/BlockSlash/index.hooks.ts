import { useAppDispatch } from '$app/stores/store';
import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { slashCommandActions } from '$app_reducers/document/slice';
import { useSubscribeNode } from '$app/components/document/_shared/SubscribeNode.hooks';
import Delta from 'quill-delta';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';
import { useSubscribeSlashState } from '$app/components/document/_shared/SubscribeSlash.hooks';
import { getDeltaText } from '$app/utils/document/delta';

export function useBlockSlash() {
  const dispatch = useAppDispatch();
  const { docId } = useSubscribeDocument();
  const { blockId, visible, slashText, hoverOption } = useSubscribeSlash();
  const [anchorPosition, setAnchorPosition] = useState<{
    top: number;
    left: number;
  }>();

  useEffect(() => {
    if (blockId && visible) {
      const blockEl = document.querySelector(`[data-block-id="${blockId}"]`) as HTMLElement;
      const el = blockEl.querySelector(`[role="textbox"]`) as HTMLElement;

      if (el) {
        const rect = el.getBoundingClientRect();

        setAnchorPosition({
          top: rect.top + rect.height,
          left: rect.left,
        });
        return;
      }
    }

    setAnchorPosition(undefined);
  }, [blockId, visible]);

  useEffect(() => {
    if (!slashText) {
      dispatch(slashCommandActions.closeSlashCommand(docId));
    }
  }, [dispatch, docId, slashText]);

  const searchText = useMemo(() => {
    if (!slashText) return '';
    if (slashText[0] !== '/') return slashText;

    return slashText.slice(1, slashText.length);
  }, [slashText]);

  const onClose = useCallback(() => {
    dispatch(slashCommandActions.closeSlashCommand(docId));
  }, [dispatch, docId]);

  const open = Boolean(anchorPosition);

  return {
    open,
    anchorPosition,
    onClose,
    blockId,
    searchText,
    hoverOption,
  };
}

export function useSubscribeSlash() {
  const slashCommandState = useSubscribeSlashState();
  const visible = slashCommandState.isSlashCommand;
  const blockId = slashCommandState.blockId;
  const rightDistanceRef = useRef<number>(0);

  const { node } = useSubscribeNode(blockId || '');

  const slashText = useMemo(() => {
    if (!node) return '';
    const delta = new Delta(node.data.delta);
    const length = delta.length();
    const slicedDelta = delta.slice(0, length - rightDistanceRef.current);

    return getDeltaText(slicedDelta);
  }, [node]);

  useEffect(() => {
    if (!visible) return;
    rightDistanceRef.current = new Delta(node.data.delta).length();
  }, [visible]);

  return {
    visible,
    blockId,
    slashText,
    hoverOption: slashCommandState.hoverOption,
  };
}
