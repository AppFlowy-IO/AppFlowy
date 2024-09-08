import { GlobalComment } from '@/application/comment.type';
import MoreActions from '@/components/global-comment/actions/MoreActions';
import ReactAction from '@/components/global-comment/actions/ReactAction';
import ReplyAction from '@/components/global-comment/actions/ReplyAction';
import React, { memo } from 'react';

function CommentActions({ comment }: { comment: GlobalComment }) {
  return (
    <>
      <ReactAction comment={comment} />
      <ReplyAction comment={comment} />
      <MoreActions comment={comment} />
    </>
  );
}

export default memo(CommentActions);
