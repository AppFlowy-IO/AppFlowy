import GlobalComment from '@/components/global-comment/GlobalComment';
import {
  GlobalCommentContext,
  useLoadComments,
  useLoadReactions,
} from '@/components/global-comment/GlobalComment.hooks';
import React, { useCallback, useState } from 'react';

export function GlobalCommentProvider() {
  const { comments, loading, reload } = useLoadComments();
  const { reactions, toggleReaction } = useLoadReactions();
  const [replyCommentId, setReplyCommentId] = useState<string | null>(null);

  const getComment = useCallback(
    (commentId: string) => {
      return comments?.find((comment) => comment.commentId === commentId);
    },
    [comments]
  );

  const replyComment = useCallback((commentId: string | null) => {
    setReplyCommentId(commentId);
  }, []);

  return (
    <GlobalCommentContext.Provider
      value={{
        reactions,
        replyCommentId,
        reload,
        getComment,
        loading,
        comments,
        replyComment,
        toggleReaction,
      }}
    >
      <GlobalComment />
    </GlobalCommentContext.Provider>
  );
}

export default GlobalCommentProvider;
