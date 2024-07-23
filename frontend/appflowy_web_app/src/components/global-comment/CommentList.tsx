import { CommentWrap } from '@/components/global-comment/comment';
import { useGlobalCommentContext } from '@/components/global-comment/GlobalComment.hooks';

import React, { memo } from 'react';

function CommentList() {
  const { comments } = useGlobalCommentContext();

  const isEmpty = !comments || comments.length === 0;

  const [hoverId, setHoverId] = React.useState<string | null>(null);

  if (isEmpty) {
    return null;
  }

  return (
    <div
      onMouseLeave={() => {
        setHoverId(null);
      }}
      className={'flex w-full flex-col gap-2'}
    >
      {comments?.map((comment) => (
        <CommentWrap
          isHovered={comment.commentId === hoverId}
          onHovered={() => {
            setHoverId(comment.commentId);
          }}
          key={comment.commentId}
          commentId={comment.commentId}
        />
      ))}
    </div>
  );
}

export default memo(CommentList);
