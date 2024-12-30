import { UIVariant, View } from '@/application/types';
import { Tooltip } from '@mui/material';
import React from 'react';
import { ReactComponent as PublishSvg } from '@/assets/publish.svg';
import { useTranslation } from 'react-i18next';

function PublishIcon ({
  variant,
  view,
}: {
  variant?: UIVariant,
  view: View;
}) {
  const { extra, is_published } = view;
  const { t } = useTranslation();

  if (extra?.is_space) {
    return null;
  }

  if (is_published && variant === 'app') {
    return (
      <PublishSvg className="h-5 w-5 shrink-0 text-function-success" />
    );
  }

  if (variant === 'publish' && !is_published) {
    return (
      <Tooltip title={t('publish.hasNotBeenPublished')}>
        <div
          className={'text-text-caption cursor-pointer hover:bg-fill-list-hover rounded h-5 w-5 flex items-center justify-center'}
        >
          <PublishSvg className={`h-4 w-4`} />
        </div>
      </Tooltip>
    );
  }

  return null;
}

export default PublishIcon;