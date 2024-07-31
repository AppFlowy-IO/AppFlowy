import { GlobalComment } from '@/application/comment.type';
import { useCommentRender } from '@/components/global-comment/GlobalComment.hooks';
import { Reactions } from '@/components/global-comment/reactions';
import { Avatar, Divider, Tooltip } from '@mui/material';
import React, { memo, useCallback, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { ReactComponent as BulletedListIcon } from '@/assets/bulleted_list_icon_1.svg';
import { ReactComponent as DoubleArrow } from '@/assets/double_arrow.svg';
import smoothScrollIntoViewIfNeeded from 'smooth-scroll-into-view-if-needed';

interface CommentProps {
  comment: GlobalComment;
}

const MAX_HEIGHT = 320;

function Comment({ comment }: CommentProps) {
  const { avatar, time, timeFormat } = useCommentRender(comment);
  const { t } = useTranslation();
  const ref = React.useRef<HTMLDivElement>(null);
  const contentRef = React.useRef<HTMLSpanElement>(null);
  const [showExpand, setShowExpand] = React.useState(false);
  const [isExpand, setIsExpand] = React.useState(false);

  useEffect(() => {
    const contentEl = contentRef.current;

    if (!contentEl) return;
    const contentHeight = contentEl.offsetHeight;

    setShowExpand(contentHeight > MAX_HEIGHT);
  }, []);

  const toggleExpand = useCallback(() => {
    setIsExpand((prev) => {
      return !prev;
    });
  }, []);

  return (
    <div className={'comment flex flex-col gap-2'} ref={ref}>
      <div className={'flex items-center gap-2'}>
        <div className={'flex items-center gap-4'}>
          <Avatar {...avatar} className={'h-8 w-8'} />
          <div className={'font-semibold'}>{comment.user?.name}</div>
        </div>
        <Tooltip title={timeFormat} enterNextDelay={500} enterDelay={1000} placement={'top-start'}>
          <div className={'flex items-center gap-2 text-text-caption'}>
            <BulletedListIcon className={'h-3 w-3'} />
            <div className={'text-sm'}>{time}</div>
          </div>
        </Tooltip>
      </div>
      <div className={'ml-12 flex flex-col gap-2'}>
        {comment.isDeleted ? (
          <span className={'text-text-caption'}>{`[${t('globalComment.hasBeenDeleted')}]`}</span>
        ) : (
          <div
            style={{
              height: showExpand && !isExpand ? MAX_HEIGHT : 'auto',
              overflow: isExpand ? 'unset' : 'hidden',
              transition: 'height 0.8s ease-in-out',
            }}
          >
            <span ref={contentRef} className={'transform whitespace-pre-wrap break-words'}>
              {comment.content}
            </span>
          </div>
        )}
        {showExpand && (
          <>
            <Tooltip
              title={isExpand ? t('globalComment.collapse') : t('globalComment.readMore')}
              disableInteractive={true}
            >
              <div
                onClick={() => {
                  const originalExpand = isExpand;

                  toggleExpand();

                  if (originalExpand && ref.current) {
                    void smoothScrollIntoViewIfNeeded(ref.current, {
                      behavior: 'smooth',
                      block: 'start',
                    });
                  }
                }}
                className={
                  'relative flex cursor-pointer items-center justify-center gap-2 bg-transparent text-text-caption hover:text-content-blue-400'
                }
              >
                <Divider className={'flex-1'} />
                <DoubleArrow className={`h-5 w-5 transform ${isExpand ? '-rotate-90' : 'rotate-90'} `} />
                <Divider className={'flex-1'} />
              </div>
            </Tooltip>
          </>
        )}
        {!comment.isDeleted && <Reactions comment={comment} />}
      </div>
    </div>
  );
}

export default memo(Comment);
