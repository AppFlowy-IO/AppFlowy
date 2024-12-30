import MoreActions from '@/components/_shared/more-actions/MoreActions';
import { openOrDownload } from '@/utils/open_schema';
import { Divider, IconButton, Tooltip } from '@mui/material';
import React, { useCallback, useContext } from 'react';
import { ReactComponent as Logo } from '@/assets/logo.svg';
import { Duplicate } from '@/components/publish/header/duplicate';
import { useTranslation } from 'react-i18next';
import { PublishContext } from '@/application/publish';
import { useCurrentUser } from '@/components/main/app.hooks';
import  { ReactComponent as TemplateIcon } from '@/assets/template.svg';

function RightMenu () {
  const { t } = useTranslation();
  const viewMeta = useContext(PublishContext)?.viewMeta;
  const viewId = viewMeta?.view_id;
  const viewName = viewMeta?.name;

  const handleTemplateClick = useCallback(() => {
    const url = `${window.origin}${window.location.pathname}`;

    window.open(`${window.origin}/as-template?viewUrl=${encodeURIComponent(url)}&viewName=${viewName || ''}&viewId=${viewId || ''}`, '_blank');
  }, [viewId, viewName]);

  const currentUser = useCurrentUser();

  const isAppFlowyUser = currentUser?.email?.endsWith('@appflowy.io');

  return (
    <>
      <MoreActions />
      <Duplicate />
      {isAppFlowyUser && (
        <Tooltip title={t('template.asTemplate')}>
          <IconButton onClick={handleTemplateClick} size={'small'}>
            <TemplateIcon />
          </IconButton>
        </Tooltip>
      )}
      <Divider
        orientation={'vertical'}
        className={'mx-2'}
        flexItem
      />
      <Tooltip title={t('publish.downloadApp')}>
        <button onClick={() => openOrDownload()}>
          <Logo className={'h-6 w-6'} />
        </button>
      </Tooltip>
    </>
  );
}

export default RightMenu;