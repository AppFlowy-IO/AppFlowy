import { useAppView, useCurrentWorkspaceId } from '@/components/app/app.hooks';
import LinkPreview from '@/components/app/share/LinkPreview';
import { useLoadPublishInfo } from '@/components/app/share/publish.hooks';
import { openOrDownload } from '@/utils/open_schema';
import { openAppFlowySchema } from '@/utils/url';
import { Button, Typography } from '@mui/material';
import React, { useCallback } from 'react';
import { useTranslation } from 'react-i18next';
import { ReactComponent as PublishIcon } from '@/assets/publish.svg';

function PublishPanel () {
  const view = useAppView();
  const currentWorkspaceId = useCurrentWorkspaceId();
  const { t } = useTranslation();
  const {
    url,
  } = useLoadPublishInfo();

  const renderPublished = useCallback(() => {
    return <div className={'flex flex-col gap-2'}>
      <LinkPreview url={url} />
      <div className={'flex items-center gap-1.5 justify-end w-full'}>
        <Button
          className={'flex-1 max-w-[50%]'} onClick={() => {
          window.open(url, '_blank');
        }} variant={'contained'}
        >{t('shareAction.visitSite')}</Button>
      </div>
    </div>;
  }, [t, url]);

  const renderUnpublished = useCallback(() => {
    return <Button
      onClick={() => {
        openOrDownload(openAppFlowySchema + '#workspace_id=' + currentWorkspaceId + '&view_id=' + view?.view_id);
      }} variant={'contained'} color={'primary'}
    >{t('shareAction.publishOnAppFlowy')}</Button>;
  }, [currentWorkspaceId, t, view?.view_id]);

  return (
    <div className={'flex flex-col gap-2'}>
      <Typography className={'flex items-center gap-1.5'} variant={'body2'}>
        <PublishIcon className={'w-4 h-4'} />
        {t('shareAction.publishToTheWeb')}
      </Typography>
      <Typography
        className={'text-text-caption'} variant={'caption'}
      >{t('shareAction.publishToTheWebHint')}</Typography>
      {view?.is_published ? renderPublished() : renderUnpublished()}
    </div>
  );
}

export default PublishPanel;