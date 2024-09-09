import { useCurrentUser } from '@/components/main/app.hooks';
import { useViewMeta } from '@/components/publish/useViewMeta';
import { Button, Divider } from '@mui/material';
import React, { useCallback } from 'react';
import { useTranslation } from 'react-i18next';
import { useNavigate } from 'react-router-dom';
import { ReactComponent as TemplateIcon } from '@/assets/template.svg';

function AsTemplateButton () {
  const { t } = useTranslation();
  const viewMeta = useViewMeta();
  const navigate = useNavigate();
  const handleClick = useCallback(() => {
    const url = encodeURIComponent(window.location.href.replace(window.location.search, ''));

    navigate(`/as-template?viewUrl=${url}&viewName=${viewMeta?.name || ''}&viewId=${viewMeta?.viewId || ''}`);
  }, [navigate, viewMeta]);

  const currentUser = useCurrentUser();

  if (!currentUser) return null;

  const isAppFlowyUser = currentUser.email?.endsWith('@appflowy.io');

  if (!isAppFlowyUser) return null;
  return (
    <>
      <Button
        onClick={handleClick} className={'text-left justify-start'} variant={'text'}
        color={'inherit'}
        startIcon={<TemplateIcon className={'w-4 h-4'} />}
      >
        {t('template.asTemplate')}
      </Button>
      <Divider />
    </>
  );
}

export default AsTemplateButton;