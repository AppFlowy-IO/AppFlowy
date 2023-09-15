import React, { useCallback } from 'react';
import { useSubscribeMentionState } from '$app/components/document/_shared/SubscribeMention.hooks';
import Popover from '@mui/material/Popover';
import { useAppDispatch } from '$app/stores/store';
import { mentionActions } from '$app_reducers/document/mention_slice';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';
import { useMentionPopoverProps } from '$app/components/document/Mention/Mention.hooks';
import RecentPages from '$app/components/document/Mention/RecentPages';
import { formatMention, MentionType } from '$app_reducers/document/async-actions/mention';
import { useSubscribePanelSearchText } from '$app/components/document/_shared/usePanelSearchText';

function MentionPopover() {
  const { docId, controller } = useSubscribeDocument();
  const { open, blockId } = useSubscribeMentionState();

  const dispatch = useAppDispatch();
  const onClose = useCallback(() => {
    dispatch(
      mentionActions.close({
        docId,
      })
    );
  }, [dispatch, docId]);

  const { searchText } = useSubscribePanelSearchText({
    blockId,
    open,
  });

  const { popoverOpen, anchorPosition } = useMentionPopoverProps({
    open,
  });

  const onSelectPage = useCallback(
    async (pageId: string) => {
      await dispatch(
        formatMention({
          controller,
          type: MentionType.PAGE,
          value: pageId,
          searchTextLength: searchText.length,
        })
      );
      onClose();
    },
    [controller, dispatch, searchText.length, onClose]
  );

  if (!open) return null;
  return (
    <Popover
      onClose={onClose}
      open={popoverOpen}
      disableAutoFocus
      disableRestoreFocus={true}
      anchorReference={'anchorPosition'}
      anchorPosition={anchorPosition}
      transformOrigin={{ vertical: 'top', horizontal: 'left' }}
      PaperProps={{
        sx: {
          height: 'auto',
          overflow: 'visible',
        },
        elevation: 0,
      }}
    >
      <div
        style={{
          boxShadow: 'var(--shadow-resize-popover)',
        }}
        className={'flex w-[420px] flex-col rounded-md bg-bg-body px-4 py-2'}
      >
        <RecentPages onSelect={onSelectPage} searchText={searchText} />
      </div>
    </Popover>
  );
}

export default MentionPopover;
