import React from 'react';
import { AddLinkOutlined } from '@mui/icons-material';
import { useTranslation } from 'react-i18next';

function TemporaryLink({ href = '', text = '' }: { href?: string; text?: string }) {
  const { t } = useTranslation();
  return (
    <span className={'bg-content-blue-100'} contentEditable={false}>
      {text ? (
        <span className={'text-text-link-default underline'}>{text}</span>
      ) : (
        <span className={'text-text-caption'}>
          <AddLinkOutlined /> {t('document.inlineLink.title.label')}
        </span>
      )}
    </span>
  );
}

export default TemporaryLink;
