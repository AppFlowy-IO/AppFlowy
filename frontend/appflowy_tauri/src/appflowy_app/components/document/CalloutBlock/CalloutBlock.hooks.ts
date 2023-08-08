import { useCallback, useMemo, useState } from 'react';
import { useAppDispatch } from '$app/stores/store';
import { updateNodeDataThunk } from '$app_reducers/document/async-actions';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';

export function useCalloutBlock(nodeId: string) {
  const [anchorEl, setAnchorEl] = useState<HTMLButtonElement | null>(null);
  const open = useMemo(() => Boolean(anchorEl), [anchorEl]);
  const id = useMemo(() => (open ? 'emoji-popover' : undefined), [open]);
  const dispatch = useAppDispatch();
  const { controller } = useSubscribeDocument();

  const closeEmojiSelect = useCallback(() => {
    setAnchorEl(null);
  }, []);

  const openEmojiSelect = useCallback((event: React.MouseEvent<HTMLButtonElement>) => {
    setAnchorEl(event.currentTarget);
  }, []);

  const onEmojiSelect = useCallback(
    (emoji: string) => {
      if (!controller) return;
      void dispatch(
        updateNodeDataThunk({
          id: nodeId,
          controller,
          data: {
            icon: emoji,
          },
        })
      );
      closeEmojiSelect();
    },
    [controller, dispatch, nodeId, closeEmojiSelect]
  );

  return {
    anchorEl,
    closeEmojiSelect,
    openEmojiSelect,
    open,
    id,
    onEmojiSelect,
  };
}
