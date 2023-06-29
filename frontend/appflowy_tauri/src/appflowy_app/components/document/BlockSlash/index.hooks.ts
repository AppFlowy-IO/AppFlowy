import { useAppDispatch } from '$app/stores/store';
import React, { useCallback, useEffect, useMemo } from 'react';
import { slashCommandActions } from '$app_reducers/document/slice';
import { useSubscribeNode } from '$app/components/document/_shared/SubscribeNode.hooks';
import { Op } from 'quill-delta';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';
import { useSubscribeSlashState } from '$app/components/document/_shared/SubscribeSlash.hooks';

export function useBlockSlash() {
  const dispatch = useAppDispatch();
  const { docId } = useSubscribeDocument();

  const { blockId, visible, slashText, hoverOption } = useSubscribeSlash();
  const [anchorPosition, setAnchorPosition] = React.useState<{
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

  const { node } = useSubscribeNode(blockId || '');

  const slashText = useMemo(() => {
    if (!node) return '';
    const delta = node.data.delta || [];

    return delta
      .map((op: Op) => {
        if (typeof op.insert === 'string') {
          return op.insert;
        } else {
          return '';
        }
      })
      .join('');
  }, [node]);

  return {
    visible,
    blockId,
    slashText,
    hoverOption: slashCommandState.hoverOption,
  };
}
