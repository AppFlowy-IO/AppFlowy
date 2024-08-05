import { CommentUser, GlobalComment, Reaction } from '@/application/comment.type';
import { PublishContext } from '@/application/publish';
import { AFConfigContext } from '@/components/app/AppConfig';
import { stringAvatar } from '@/utils/color';
import dayjs from 'dayjs';
import React, { useCallback, useContext, useEffect, useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';

export const GlobalCommentContext = React.createContext<{
  reload: () => Promise<void>;
  getComment: (commentId: string) => GlobalComment | undefined;
  loading: boolean;
  comments: GlobalComment[] | null;
  replyComment: (commentId: string | null) => void;
  replyCommentId: string | null;
  reactions: Record<string, Reaction[]> | null;
  toggleReaction: (commentId: string, reactionType: string) => void;
  setHighLightCommentId: (commentId: string | null) => void;
  highLightCommentId: string | null;
}>({
  reload: () => Promise.resolve(),
  getComment: () => undefined,
  loading: false,
  comments: null,
  replyComment: () => undefined,
  replyCommentId: null,
  reactions: null,
  toggleReaction: () => undefined,
  setHighLightCommentId: () => undefined,
  highLightCommentId: null,
});

export function useGlobalCommentContext() {
  return useContext(GlobalCommentContext);
}

export function useLoadReactions() {
  const viewId = useContext(PublishContext)?.viewMeta?.view_id;
  const service = useContext(AFConfigContext)?.service;
  const currentUser = useContext(AFConfigContext)?.currentUser;
  const [reactions, setReactions] = useState<Record<string, Reaction[]> | null>(null);
  const fetchReactions = useCallback(async () => {
    if (!viewId || !service) return;

    try {
      const reactions = await service.getPublishViewReactions(viewId);

      setReactions(reactions);
    } catch (e) {
      console.error(e);
    }
  }, [service, viewId]);

  useEffect(() => {
    void fetchReactions();
  }, [fetchReactions]);

  const toggleReaction = useCallback(
    async (commentId: string, reactionType: string) => {
      try {
        if (!service || !viewId) return;
        let isAdded = true;

        setReactions((prev) => {
          const commentReactions = prev?.[commentId] || [];
          const reaction = commentReactions.find((reaction) => reaction.reactionType === reactionType);
          const reactUsers = reaction?.reactUsers || [];
          const hasReacted = reactUsers.some((user) => user.uuid === currentUser?.uuid);
          let newReaction: Reaction | null = null;
          let index = -1;
          const reactUser = {
            uuid: currentUser?.uuid || '',
            name: currentUser?.name || '',
            avatarUrl: currentUser?.avatar || null,
          };

          // If the reaction does not exist, create a new reaction.
          if (!reaction) {
            index = commentReactions.length;
            newReaction = {
              reactionType,
              reactUsers: [reactUser],
              commentId,
            };
          } else {
            let newReactUsers: CommentUser[] = [];

            // If the user has not reacted, add the user to the reaction.
            if (!hasReacted) {
              newReactUsers = [...reactUsers, reactUser];

              // If the user has reacted, remove the user from the reaction.
            } else {
              isAdded = false;
              newReactUsers = reactUsers.filter((user) => user.uuid !== currentUser?.uuid);
            }

            newReaction = {
              reactionType,
              reactUsers: newReactUsers,
              commentId,
            };
            index = commentReactions.findIndex((reaction) => reaction.reactionType === reactionType);
          }

          const newReactions = [...commentReactions];

          if (!newReaction) return prev;
          // If the reaction does not exist, add the reaction to the list.
          if (index === -1) {
            newReactions.push(newReaction);
            // If the reaction exists, update the reaction.
          } else {
            newReactions.splice(index, 1, newReaction);
          }

          return {
            ...prev,
            [commentId]: newReactions,
          };
        });

        try {
          if (isAdded) {
            await service.addPublishViewReaction(viewId, commentId, reactionType);
          } else {
            await service.removePublishViewReaction(viewId, commentId, reactionType);
          }
        } catch (e) {
          console.error(e);
        }
      } catch (e) {
        console.error(e);
      }
    },
    [currentUser, service, viewId]
  );

  return { reactions, toggleReaction };
}

export function useLoadComments() {
  const viewId = useContext(PublishContext)?.viewMeta?.view_id;
  const service = useContext(AFConfigContext)?.service;

  const [comments, setComments] = useState<GlobalComment[] | null>(null);
  const [loading, setLoading] = useState(false);

  const fetchComments = useCallback(async () => {
    if (!viewId || !service) return;

    setLoading(true);
    try {
      const comments = await service.getPublishViewGlobalComments(viewId);

      setComments(comments);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  }, [viewId, service]);

  useEffect(() => {
    void fetchComments();
  }, [fetchComments]);

  return { comments, loading, reload: fetchComments };
}

export function getAvatar(comment: GlobalComment) {
  if (comment.user?.avatarUrl) {
    return {
      children: <span>{comment.user.avatarUrl}</span>,
    };
  }

  return stringAvatar(comment.user?.name || '');
}

export function useCommentRender(comment: GlobalComment) {
  const { t } = useTranslation();
  const avatar = useMemo(() => {
    return getAvatar(comment);
  }, [comment]);

  const timeFormat = useMemo(() => {
    const time = dayjs(comment.lastUpdatedAt);

    return time.format('YYYY-MM-DD HH:mm:ss');
  }, [comment.lastUpdatedAt]);

  const time = useMemo(() => {
    if (!comment.lastUpdatedAt) return '';
    const now = dayjs();
    const past = dayjs(comment.lastUpdatedAt);
    const diffSec = now.diff(past, 'second');
    const diffMin = now.diff(past, 'minute');
    const diffHour = now.diff(past, 'hour');
    const diffDay = now.diff(past, 'day');
    const diffMonth = now.diff(past, 'month');
    const diffYear = now.diff(past, 'year');

    if (diffSec < 5) {
      return t('globalComment.showSeconds', {
        count: 0,
      });
    }

    if (diffMin < 1) {
      return t('globalComment.showSeconds', {
        count: diffSec,
      });
    }

    if (diffHour < 1) {
      return t('globalComment.showMinutes', {
        count: diffMin,
      });
    }

    if (diffDay < 1) {
      return t('globalComment.showHours', {
        count: diffHour,
      });
    }

    if (diffMonth < 1) {
      return t('globalComment.showDays', {
        count: diffDay,
      });
    }

    if (diffYear < 1) {
      return t('globalComment.showMonths', {
        count: diffMonth,
      });
    }

    return t('globalComment.showYears', {
      count: diffYear,
    });
  }, [t, comment]);

  return { avatar, time, timeFormat };
}
