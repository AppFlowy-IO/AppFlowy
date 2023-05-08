import { useCallback, useContext, useMemo, useState } from 'react';
import emojiData, { EmojiMartData, Emoji } from '@emoji-mart/data';
import { useAppDispatch } from '$app/stores/store';
import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';
import { updateNodeDataThunk } from '$app_reducers/document/async-actions';

export function useCalloutBlock(nodeId: string) {
  const [anchorEl, setAnchorEl] = useState<HTMLButtonElement | null>(null);
  const open = useMemo(() => Boolean(anchorEl), [anchorEl]);
  const id = useMemo(() => (open ? 'emoji-popover' : undefined), [open]);
  const dispatch = useAppDispatch();
  const controller = useContext(DocumentControllerContext);

  const closeEmojiSelect = useCallback(() => {
    setAnchorEl(null);
  }, []);

  const openEmojiSelect = useCallback((event: React.MouseEvent<HTMLButtonElement>) => {
    setAnchorEl(event.currentTarget);
  }, []);

  const onEmojiSelect = useCallback(
    (emoji: { native: string }) => {
      if (!controller) return;
      console.log('emoji', emoji.native);
      void dispatch(
        updateNodeDataThunk({
          id: nodeId,
          controller,
          data: {
            icon: emoji.native,
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
