import { useGlobalCommentContext } from '@/components/global-comment/GlobalComment.hooks';
import { getScrollParent } from '@/components/global-comment/utils';
import { HEADER_HEIGHT } from '@/components/publish/header';
import React, { useEffect, useRef, useState } from 'react';
import AddComment from './AddComment';
import { Portal } from '@mui/material';

export function AddCommentWrapper() {
  const { replyCommentId } = useGlobalCommentContext();
  const addCommentRef = useRef<HTMLDivElement>(null);
  const [showFixedAddComment, setShowFixedAddComment] = useState(false);
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
      const isIntersecting = element.getBoundingClientRect().top < HEADER_HEIGHT;

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

  return (
    <>
      <div className={'my-2'} id='addComment' ref={addCommentRef}>
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
          <div className={'fixed top-[48px] flex w-full justify-center'}>
            <div className={'w-[964px] min-w-0 max-w-full px-16 max-sm:px-4'}>
              <AddComment fixed content={content} setContent={setContent} focus={focus} setFocus={setFocus} />
            </div>
          </div>
        </Portal>
      )}
    </>
  );
}

export default AddCommentWrapper;
