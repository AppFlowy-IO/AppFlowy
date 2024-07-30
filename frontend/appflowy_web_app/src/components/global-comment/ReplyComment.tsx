import { getAvatar, useGlobalCommentContext } from '@/components/global-comment/GlobalComment.hooks';
import { Avatar } from '@mui/material';
import React, { useMemo } from 'react';
import { useTranslation } from 'react-i18next';

function ReplyComment({ commentId }: { commentId?: string | null }) {
  const { getComment } = useGlobalCommentContext();
  const { t } = useTranslation();
  const replyComment = useMemo(() => {
    if (!commentId) return;
    return getComment(commentId);
  }, [commentId, getComment]);

  const avatar = useMemo(() => (replyComment ? getAvatar(replyComment) : null), [replyComment]);

  if (!replyComment) return null;
  return (
    <div className={'flex items-center gap-1 text-sm text-text-caption'}>
      <Avatar {...avatar} className={'h-4 w-4 text-xs'} />
      <div className={'text-xs font-medium'}>@{replyComment.user?.name}</div>
      <div className={'truncate px-1'}>
        {replyComment.isDeleted ? (
          <span className={'text-xs'}>{`[${t('globalComment.hasBeenDeleted')}]`}</span>
        ) : (
          replyComment.content
        )}
      </div>
    </div>
  );
}

export default ReplyComment;
