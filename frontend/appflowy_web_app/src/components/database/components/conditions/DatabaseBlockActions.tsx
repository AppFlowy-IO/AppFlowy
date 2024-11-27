import { ReactComponent as ExpandMoreIcon } from '@/assets/full_view.svg';
import { DatabaseContext } from '@/application/database-yjs';
import { IconButton, Tooltip } from '@mui/material';
import React, { useContext } from 'react';
import { useTranslation } from 'react-i18next';

function DatabaseBlockActions () {
  const { t } = useTranslation();
  const context = useContext(DatabaseContext);
  const navigateToView = context?.navigateToView;
  const viewId = context?.viewId;

  return (
    <div className={'flex items-center gap-2'}>
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