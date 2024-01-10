import React from 'react';
import { useTranslation } from 'react-i18next';
import Button from '@mui/material/Button';
import { useShareConfig } from '$app/components/layout/share/Share.hooks';

function ShareButton() {
  const { showShareButton } = useShareConfig();
  const { t } = useTranslation();

  if (!showShareButton) return null;
  return <Button variant={'contained'}>{t('shareAction.buttonText')}</Button>;
}

export default ShareButton;
