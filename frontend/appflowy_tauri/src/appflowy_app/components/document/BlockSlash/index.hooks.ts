import { useAppDispatch } from '$app/stores/store';
import { useCallback, useEffect, useMemo, useState } from 'react';
import { slashCommandActions } from '$app_reducers/document/slice';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';
import { useSubscribeSlashState } from '$app/components/document/_shared/SubscribeSlash.hooks';
import { useSubscribePanelSearchText } from '$app/components/document/_shared/usePanelSearchText';

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
  const { searchText } = useSubscribePanelSearchText({ blockId: '', open: visible });

  return {
    visible,
    blockId,
    slashText: searchText,
    hoverOption: slashCommandState.hoverOption,
  };
}
