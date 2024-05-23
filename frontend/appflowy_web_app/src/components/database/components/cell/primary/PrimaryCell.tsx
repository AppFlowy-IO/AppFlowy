import { ReactComponent as ExpandMoreIcon } from '$icons/16x/full_view.svg';
import { useNavigateToRow, useRowMetaSelector } from '@/application/database-yjs';
import { TextCell as CellType, CellProps } from '@/components/database/components/cell/cell.type';
import { TextCell } from '@/components/database/components/cell/text';
import { Tooltip } from '@mui/material';
import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';

export function PrimaryCell(props: CellProps<CellType>) {
  const navigateToRow = useNavigateToRow();
  const { rowId } = props;
  // const icon = null;
  const icon = useRowMetaSelector(rowId)?.icon;

  const [hover, setHover] = useState(false);
  const { t } = useTranslation();

  return (
    <div
      onMouseEnter={() => setHover(true)}
      onMouseLeave={() => setHover(false)}
      className={'primary-cell relative flex w-full items-center gap-2'}
    >
      {icon && <div className={'h-4 w-4'}>{icon}</div>}
      <TextCell {...props} />

      {hover && (
        <Tooltip placement={'bottom'} title={t('tooltip.openAsPage')}>
          <button
            color={'primary'}
            className={
              'absolute right-0 top-1/2 min-w-0 -translate-y-1/2 transform rounded border border-line-divider bg-bg-body p-1 hover:bg-fill-list-hover'
            }
            onClick={() => {
              navigateToRow?.(rowId);
            }}
          >
            <ExpandMoreIcon />
          </button>
        </Tooltip>
      )}
    </div>
  );
}

export default PrimaryCell;
