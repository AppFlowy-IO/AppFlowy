import { ReactComponent as ExpandMoreIcon } from '$icons/16x/full_view.svg';
import { useNavigateToRow, useRowMetaSelector } from '@/application/database-yjs';
import { TextCell as CellType, CellProps } from '@/components/database/components/cell/cell.type';
import { TextCell } from '@/components/database/components/cell/text';
import { Tooltip } from '@mui/material';
import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';

export function PrimaryCell(props: CellProps<CellType>) {
  const navigateToRow = useNavigateToRow();
  const { rowId } = props;
  const icon = useRowMetaSelector(rowId)?.icon;

  const [hover, setHover] = useState(false);
  const { t } = useTranslation();

  useEffect(() => {
    const table = document.querySelector('.grid-table');

    if (!table) {
      return;
    }

    const onMouseMove = (e: Event) => {
      const target = e.target as HTMLElement;

      if (target.closest('.grid-row-cell')?.getAttribute('data-row-id') === rowId) {
        setHover(true);
      } else {
        setHover(false);
      }
    };

    table.addEventListener('mousemove', onMouseMove);
    return () => {
      table.removeEventListener('mousemove', onMouseMove);
    };
  }, [rowId]);
  return (
    <div className={'primary-cell relative flex min-h-full w-full items-center gap-2'}>
      {icon && <div className={'h-4 w-4'}>{icon}</div>}
      <div className={'flex-1 overflow-x-hidden'}>
        <TextCell {...props} />
      </div>

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
