import { GlobalComment } from '@/application/comment.type';
import MoreActions from '@/components/global-comment/actions/MoreActions';
import ReactAction from '@/components/global-comment/actions/ReactAction';
import ReplyAction from '@/components/global-comment/actions/ReplyAction';
import React, { memo } from 'react';

function CommentActions({ comment }: { comment: GlobalComment }) {
  return (
    <div className={'flex gap-2'}>
      <ReactAction comment={comment} />
      <ReplyAction comment={comment} />
      <MoreActions comment={comment} />
    </div>
  );
}

export default memo(CommentActions);
