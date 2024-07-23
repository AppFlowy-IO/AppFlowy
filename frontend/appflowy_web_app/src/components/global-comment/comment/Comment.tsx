import { GlobalComment } from '@/application/comment.type';
import { useCommentRender } from '@/components/global-comment/GlobalComment.hooks';
import { Reactions } from '@/components/global-comment/reactions';
import { Avatar, Tooltip } from '@mui/material';
import React, { memo } from 'react';
import { useTranslation } from 'react-i18next';

interface CommentProps {
  comment: GlobalComment;
}

function Comment({ comment }: CommentProps) {
  const { avatar, time, timeFormat } = useCommentRender(comment);
  const { t } = useTranslation();

  return (
    <div className={' flex gap-4 '}>
      <Avatar {...avatar} />
      <div className={'flex flex-col gap-1'}>
        <div className={'flex items-center gap-2'}>
          <div className={'font-semibold'}>{comment.user?.name}</div>
          <Tooltip title={timeFormat} enterNextDelay={500} enterDelay={1000} placement={'top-start'}>
            <div className={'text-sm text-text-caption'}>{time}</div>
          </Tooltip>
        </div>
        <div className={'whitespace-pre-wrap break-words'}>
          {comment.isDeleted ? (
            <span className={'text-text-caption'}>{`[${t('globalComment.hasBeenDeleted')}]`}</span>
          ) : (
            comment.content
          )}
        </div>
        {!comment.isDeleted && <Reactions comment={comment} />}
      </div>
    </div>
  );
}

export default memo(Comment);
