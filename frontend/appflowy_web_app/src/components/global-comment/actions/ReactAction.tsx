import { GlobalComment } from '@/application/comment.type';
import { EmojiPicker } from '@/components/_shared/emoji-picker';
import { EMOJI_SIZE, PER_ROW_EMOJI_COUNT } from '@/components/_shared/emoji-picker/const';
import { Popover } from '@/components/_shared/popover';
import ComponentLoading from '@/components/_shared/progress/ComponentLoading';
import { useGlobalCommentContext } from '@/components/global-comment/GlobalComment.hooks';
import { ReactComponent as AddReactionRounded } from '@/assets/add_reaction.svg';
import { IconButton, Tooltip } from '@mui/material';
import React, { memo, Suspense, useCallback } from 'react';
import { useTranslation } from 'react-i18next';

function ReactAction({ comment }: { comment: GlobalComment }) {
  const { toggleReaction } = useGlobalCommentContext();
  const { t } = useTranslation();
  const ref = React.useRef<HTMLButtonElement>(null);
  const [open, setOpen] = React.useState(false);
  const handleClose = useCallback(() => {
    setOpen(false);
  }, []);

  const handleOpen = () => {
    setOpen(true);
  };

  const handlePickEmoji = useCallback(
    (emoji: string) => {
      toggleReaction(comment.commentId, emoji);
      handleClose();
    },
    [comment.commentId, handleClose, toggleReaction]
  );

  return (
    <>
      <Tooltip title={t('globalComment.addReaction')}>
        <IconButton ref={ref} onClick={handleOpen} size='small'>
          <AddReactionRounded className={'h-5 w-5'} />
        </IconButton>
      </Tooltip>
      {open && (
        <Popover
          anchorEl={ref.current}
          open={open}
          onClose={handleClose}
          anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
          transformOrigin={{ vertical: 'top', horizontal: 'right' }}
          sx={{
            '& .MuiPopover-paper': {
              width: PER_ROW_EMOJI_COUNT * EMOJI_SIZE,
            },
          }}
        >
          <Suspense fallback={<ComponentLoading />}>
            <EmojiPicker hideRemove onEscape={handleClose} onEmojiSelect={handlePickEmoji} />
          </Suspense>
        </Popover>
      )}
    </>
  );
}

export default memo(ReactAction);
