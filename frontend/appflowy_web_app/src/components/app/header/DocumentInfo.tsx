import { useAppView, useAppWordCount } from '@/components/app/app.hooks';
import { Divider } from '@mui/material';
import dayjs from 'dayjs';
import React, { useCallback } from 'react';
import { useTranslation } from 'react-i18next';

function DocumentInfo ({ viewId }: {
  viewId: string;
}) {
  const view = useAppView(viewId);
  const { t } = useTranslation();
  const wordCount = useAppWordCount(viewId);
  const formatTime = useCallback((timestamp: string) => {
    const now = dayjs();
    const past = dayjs(timestamp);

    const diffSec = now.diff(past, 'second');
    const diffMin = now.diff(past, 'minute');
    const diffHour = now.diff(past, 'hour');

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

    return dayjs(timestamp).format('MMM D, YYYY hh:mm');
  }, [t]);

  if (!view) return null;

  return (
    <>
      <Divider />
      <div className={'flex flex-col gap-1 text-text-caption text-xs '}>
        <div
          className={'px-[10px]'}
        >
          {t('moreAction.wordCountLabel')}{wordCount?.words}
        </div>
        <div className={'px-[10px]'}>
          {t('moreAction.charCountLabel')}{wordCount?.characters}
        </div>
        {view.created_at && <div className={'px-[10px]'}>
          {t('moreAction.createdAtLabel')}{formatTime(view.created_at)}
        </div>}


      </div>
    </>
  );
}

export default DocumentInfo;