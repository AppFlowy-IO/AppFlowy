import { useGlobalCommentContext } from '@/components/global-comment/GlobalComment.hooks';
import { getScrollParent } from '@/components/global-comment/utils';
import { HEADER_HEIGHT } from '@/application/constants';
import React, { useEffect, useRef, useState } from 'react';
import AddComment from './AddComment';
import { Portal } from '@mui/material';

export function AddCommentWrapper () {
  const { replyCommentId } = useGlobalCommentContext();
  const addCommentRef = useRef<HTMLDivElement>(null);
  const [showFixedAddComment, setShowFixedAddComment] = useState(false);
  const [offsetLeft, setOffsetLeft] = useState(0);
  const [focus, setFocus] = useState(false);
  const [content, setContent] = useState('');

  useEffect(() => {
    if (replyCommentId) {
      setFocus(true);
    }
  }, [replyCommentId]);

  useEffect(() => {
    const element = addCommentRef.current;

    if (!element) return;

    const scrollContainer = getScrollParent(element);

    if (!scrollContainer) return;

    const handleScroll = () => {
      const rect = element.getBoundingClientRect();
      const isIntersecting = rect.top < HEADER_HEIGHT;

      if (isIntersecting) {
        setShowFixedAddComment(true);
      } else {
        setShowFixedAddComment(false);
      }
    };

    scrollContainer.addEventListener('scroll', handleScroll);
    return () => {
      scrollContainer.removeEventListener('scroll', handleScroll);
    };
  }, []);

  useEffect(() => {
    const element = addCommentRef.current;

    if (!element) return;
    const scrollContainer = getScrollParent(element);

    if (!scrollContainer) return;
    if (showFixedAddComment) {
      setOffsetLeft(scrollContainer.getBoundingClientRect().left || 0);
    } else {
      setOffsetLeft(0);
    }
  }, [showFixedAddComment]);

  return (
    <>
      <div className={'my-2'} id="addComment" ref={addCommentRef}>
        <AddComment
          content={content}
          setContent={setContent}
          focus={focus && !showFixedAddComment}
          setFocus={setFocus}
          fixed={false}
        />
      </div>
      {showFixedAddComment && (
        <Portal container={document.body}>
          <div
            style={{
              left: offsetLeft + 'px',
              width: `calc(100% - ${offsetLeft}px)`,
            }} className={'fixed top-[48px] flex w-full justify-center'}
          >
            <div className={'w-[964px] min-w-0 max-w-full px-6'}>
              <AddComment fixed content={content} setContent={setContent} focus={focus} setFocus={setFocus} />
            </div>
          </div>
        </Portal>
      )}
    </>
  );
}

export default AddCommentWrapper;
