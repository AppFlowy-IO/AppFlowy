import { ReactComponent as ExpandMoreIcon } from '$icons/16x/full_view.svg';
import { useTranslation } from 'react-i18next';
import { useNavigateToRow } from '@/application/database-yjs';
import { Tooltip } from '@mui/material';
import React from 'react';

function OpenAction({ rowId }: { rowId: string }) {
  const navigateToRow = useNavigateToRow();

  const { t } = useTranslation();

  return (
    <Tooltip placement={'bottom'} title={t('tooltip.openAsPage')}>
      <button
        color={'primary'}
        className={'rounded border border-line-divider bg-bg-body p-1 hover:bg-fill-list-hover'}
        onClick={() => {
          navigateToRow?.(rowId);
        }}
      >
        <ExpandMoreIcon />
      </button>
    </Tooltip>
  );
}

export default OpenAction;
