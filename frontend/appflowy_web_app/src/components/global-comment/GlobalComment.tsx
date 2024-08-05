import { AddCommentWrapper } from '@/components/global-comment/add-comment';
import CommentList from '@/components/global-comment/CommentList';
import { useGlobalCommentContext } from '@/components/global-comment/GlobalComment.hooks';
import { Divider } from '@mui/material';
import CircularProgress from '@mui/material/CircularProgress';
import React from 'react';
import { useTranslation } from 'react-i18next';

function GlobalComment() {
  const { t } = useTranslation();
  const { loading, comments } = useGlobalCommentContext();

  return (
    <div className={'mb-[480px] mt-16 flex h-fit w-full justify-center max-md:mb-[100px]'}>
      <div
        className={
          'flex w-[964px] min-w-0 max-w-full transform flex-col gap-2 px-16 transition-all duration-300 ease-in-out max-sm:px-4'
        }
      >
        <div className={'text-[24px]'}>{t('globalComment.comments')}</div>
        <Divider />
        <AddCommentWrapper />

        {loading && !comments?.length ? (
          <div className={'flex h-[200px] w-full items-center justify-center'}>
            <CircularProgress />
          </div>
        ) : (
          <CommentList />
        )}
      </div>
    </div>
  );
}

export default GlobalComment;
