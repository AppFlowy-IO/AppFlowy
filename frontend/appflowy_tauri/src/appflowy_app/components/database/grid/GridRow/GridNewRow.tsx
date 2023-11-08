import { FC, useCallback } from 'react';
import { t } from 'i18next';
import { Button } from '@mui/material';
import { ReactComponent as AddSvg } from '$app/assets/add.svg';
import { useViewId } from '$app/hooks';
import { rowService } from '../../application';

export interface GridNewRowProps {
  startRowId?: string;
  groupId?: string;
}

export const GridNewRow: FC<GridNewRowProps> = ({ startRowId, groupId }) => {
  const viewId = useViewId();

  const handleClick = useCallback(() => {
    void rowService.createRow(viewId, {
      startRowId,
      groupId,
    });
  }, [viewId, groupId, startRowId]);

  return (
    <div className='flex grow border-b border-line-divider'>
      <Button className='grow justify-start' onClick={handleClick} color={'inherit'}>
        <span className='sticky left-2 inline-flex items-center'>
          <AddSvg className='mr-1 text-base' />
          {t('grid.row.newRow')}
        </span>
      </Button>
    </div>
  );
};
