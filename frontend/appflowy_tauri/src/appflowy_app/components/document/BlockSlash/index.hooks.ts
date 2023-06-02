import { useAppDispatch, useAppSelector } from '$app/stores/store';
import React, { useCallback, useEffect, useMemo } from 'react';
import { slashCommandActions } from '$app_reducers/document/slice';
import { useSubscribeNode } from '$app/components/document/_shared/SubscribeNode.hooks';
import { Op } from 'quill-delta';

export function useBlockSlash() {
  const dispatch = useAppDispatch();
  const { blockId, visible, slashText } = useSubscribeSlash();
  const [anchorEl, setAnchorEl] = React.useState<HTMLElement | null>(null);
  useEffect(() => {
    if (blockId && visible) {
      const el = document.querySelector(`[data-block-id="${blockId}"]`) as HTMLElement;
      if (el) {
        setAnchorEl(el);
        return;
      }
    }
    setAnchorEl(null);
  }, [blockId, visible]);

  useEffect(() => {
    if (!slashText) {
      dispatch(slashCommandActions.closeSlashCommand());
    }
  }, [dispatch, slashText]);

  const searchText = useMemo(() => {
    if (!slashText) return '';
    if (slashText[0] !== '/') return slashText;
    return slashText.slice(1, slashText.length);
  }, [slashText]);
  const onClose = useCallback(() => {
    dispatch(slashCommandActions.closeSlashCommand());
  }, [dispatch]);

  const open = Boolean(anchorEl);

  return {
    open,
    anchorEl,
    onClose,
    blockId,
    searchText,
  };
}
export function useSubscribeSlash() {
  const slashCommandState = useAppSelector((state) => state.documentSlashCommand);

  const visible = useMemo(() => slashCommandState.isSlashCommand, [slashCommandState.isSlashCommand]);
  const blockId = useMemo(() => slashCommandState.blockId, [slashCommandState.blockId]);
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
  };
}
