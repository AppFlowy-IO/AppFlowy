import { Reaction as ReactionType } from '@/application/comment.type';
import { AFConfigContext } from '@/components/app/AppConfig';
import { Tooltip } from '@mui/material';
import React, { memo, useContext, useMemo } from 'react';
import { useTranslation } from 'react-i18next';

function Reaction({ reaction, onClick }: { reaction: ReactionType; onClick: (reaction: ReactionType) => void }) {
  const { t } = useTranslation();
  const isAuthenticated = useContext(AFConfigContext)?.isAuthenticated;
  const openLoginModal = useContext(AFConfigContext)?.openLoginModal;
  const url = window.location.href + '#comment-' + reaction.commentId;
  const reactCount = useMemo(() => {
    return reaction.reactUsers.length;
  }, [reaction.reactUsers]);
  const userNames = useMemo(() => {
    let sliceOffset = reactCount;
    let suffix = '';

    if (reactCount > 20) {
      sliceOffset = 20;
      suffix = ` ${t('globalComment.reactedByMore', { count: reactCount - 20 })}`;
    }

    return (
      reaction.reactUsers
        .slice(0, sliceOffset)
        .map((user) => user.name)
        .join(', ') + suffix
    );
  }, [reaction.reactUsers, t, reactCount]);
  const currentUser = useContext(AFConfigContext)?.currentUser;
  const currentUid = currentUser?.uuid;

  const isCurrentUserReacted = useMemo(() => {
    return reaction.reactUsers.some((user) => user.uuid === currentUid);
  }, [currentUid, reaction.reactUsers]);

  const [hover, setHover] = React.useState(false);
  const style = useMemo(() => {
    const styleProperties: React.CSSProperties = {};

    if (hover) {
      Object.assign(styleProperties, {
        borderColor: 'var(--line-border)',
        backgroundColor: 'var(--bg-body)',
      });
    } else if (isCurrentUserReacted) {
      Object.assign(styleProperties, {
        borderColor: 'var(--content-blue-400)',
        backgroundColor: 'var(--content-blue-100)',
      });
    }

    return styleProperties;
  }, [hover, isCurrentUserReacted]);

  return (
    <Tooltip
      title={
        <div className={'break-word overflow-hidden whitespace-pre-wrap text-xs'}>
          {t('globalComment.reactedBy')}
          {` `}
          {userNames}
        </div>
      }
    >
      <div
        style={style}
        onClick={() => {
          if (!isAuthenticated && openLoginModal) {
            openLoginModal(url);
            return;
          }

          onClick(reaction);
        }}
        onMouseEnter={() => setHover(true)}
        onMouseLeave={() => setHover(false)}
        className={
          'flex cursor-pointer items-center gap-1 rounded-full border border-transparent bg-fill-list-hover px-1 py-0.5 text-sm'
        }
      >
        <span className={''}>{reaction.reactionType}</span>
        {<div className={'text-xs font-medium'}>{reactCount}</div>}
      </div>
    </Tooltip>
  );
}

export default memo(Reaction);
