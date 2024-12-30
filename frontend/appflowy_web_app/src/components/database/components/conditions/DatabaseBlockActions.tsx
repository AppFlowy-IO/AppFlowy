import { ReactComponent as ExpandMoreIcon } from '@/assets/full_view.svg';
import { useDatabaseContext } from '@/application/database-yjs';
import { IconButton, Tooltip } from '@mui/material';
import React from 'react';
import { useTranslation } from 'react-i18next';

function DatabaseBlockActions () {
  const { t } = useTranslation();
  const context = useDatabaseContext();
  const navigateToView = context?.navigateToView;
  const viewId = context?.viewId;

  return (
    <div className={'flex items-center gap-1.5'}>
      <Tooltip
        placement={'bottom'}
        title={t('tooltip.openAsPage')}
      >
        <IconButton
          onClick={() => {
            if (!viewId) return;
            void navigateToView?.(viewId);
          }}
          size={'small'}
        >
          <ExpandMoreIcon />
        </IconButton>
      </Tooltip>
    </div>
  );
}

export default DatabaseBlockActions;