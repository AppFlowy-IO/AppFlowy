import { IconButton, Tooltip } from '@mui/material';
import { FC, PropsWithChildren, useCallback } from 'react';
import { t } from 'i18next';
import { ReactComponent as AddSvg } from '$app/assets/add.svg';
import { useViewId } from '$app/hooks';
import { rowService } from '../../../application';

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
    void rowService.createRow(viewId, {
      startRowId: rowId,
    });
  }, [viewId, rowId]);

  return (
    <div className={`inline-flex items-center ${className}`}>
      <Tooltip placement="top" title={t('grid.row.add')}>
        <IconButton onClick={handleInsertRowClick}>
          <AddSvg />
        </IconButton>
      </Tooltip>
      {children}
    </div>
  );
};
