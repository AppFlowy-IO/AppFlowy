import { GlobalComment } from '@/application/comment.type';
import { useGlobalCommentContext } from '@/components/global-comment/GlobalComment.hooks';
import { ReactComponent as ReplyOutlined } from '@/assets/reply.svg';
import { Tooltip } from '@mui/material';
import React, { memo } from 'react';
import { useTranslation } from 'react-i18next';
import IconButton from '@mui/material/IconButton';

function ReplyAction({ comment }: { comment: GlobalComment }) {
  const { t } = useTranslation();
  const replyComment = useGlobalCommentContext().replyComment;

  return (
    <Tooltip title={t('globalComment.reply')}>
      <IconButton
        onClick={() => {
          replyComment(comment.commentId);
        }}
        size='small'
      >
        <ReplyOutlined className={'h-5 w-5'} />
      </IconButton>
    </Tooltip>
  );
}

export default memo(ReplyAction);
