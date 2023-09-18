import { IconButton } from '@mui/material';
import { FC, PropsWithChildren, useCallback } from 'react';
import { ReactComponent as AddSvg } from '$app/assets/add.svg';
import * as service from '$app/components/database/database_bd_svc';
import { useViewId } from '../../database.hooks';

export interface GridCellRowActionsProps {
  className?: string;
  rowId: string;
}

export const GridCellRowActions: FC<PropsWithChildren<GridCellRowActionsProps>> = ({
  className,
  rowId,
  children,
}) => {
  const viewId = useViewId();

  const handleInsertRowClick = useCallback(() => {
    void service.createRow(viewId, {
      startRowId: rowId,
    });
  }, [viewId, rowId]);

  return (
    <div className={['inline-flex items-center', className].join(' ')}>
      <IconButton onClick={handleInsertRowClick}>
        <AddSvg />
      </IconButton>
      {children}
    </div>
  );
};
