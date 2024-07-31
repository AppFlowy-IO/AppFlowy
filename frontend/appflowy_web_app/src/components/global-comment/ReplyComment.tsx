import { getAvatar, useGlobalCommentContext } from '@/components/global-comment/GlobalComment.hooks';
import { Avatar } from '@mui/material';
import React, { useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import smoothScrollIntoViewIfNeeded from 'smooth-scroll-into-view-if-needed';

function ReplyComment({ commentId }: { commentId?: string | null }) {
  const { getComment, setHighLightCommentId } = useGlobalCommentContext();
  const { t } = useTranslation();
  const replyComment = useMemo(() => {
    if (!commentId) return;
    return getComment(commentId);
  }, [commentId, getComment]);

  const avatar = useMemo(() => (replyComment ? getAvatar(replyComment) : null), [replyComment]);

  const handleClick = () => {
    if (commentId) {
      const element = document.querySelector('[data-comment-id="' + commentId + '"]');

      if (element) {
        void smoothScrollIntoViewIfNeeded(element, {
          behavior: 'smooth',
          block: 'center',
        });
        setHighLightCommentId(commentId);
      }
    }
  };

  if (!replyComment) return null;
  return (
    <div className={'flex items-center gap-1 text-sm text-text-caption'}>
      <Avatar {...avatar} className={'h-4 w-4 text-xs'} />
      <div className={'whitespace-nowrap text-xs font-medium text-content-blue-400'}>@{replyComment.user?.name}</div>
      <div onClick={handleClick} className={'cursor-pointer truncate px-1 hover:text-text-title'}>
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
