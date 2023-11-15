import { IconButton, Tooltip } from '@mui/material';
import { DragEventHandler, FC, HTMLAttributes, PropsWithChildren, useCallback, useRef, useState } from 'react';
import { t } from 'i18next';
import { ReactComponent as AddSvg } from '$app/assets/add.svg';
import { useViewId } from '$app/hooks';
import { rowService } from '../../../application';
import { ReactComponent as DragSvg } from '$app/assets/drag.svg';
import GridCellRowMenu from '$app/components/database/grid/GridRow/GridCellRow/GridCellRowMenu';
import Popover from '@mui/material/Popover';

export interface GridCellRowActionsProps extends HTMLAttributes<HTMLDivElement> {
  rowId: string;
  getPrevRowId: (id: string) => string | null;
  dragProps: {
    draggable?: boolean;
    onDragStart?: DragEventHandler;
    onDragEnd?: DragEventHandler;
  };
  isHidden?: boolean;
}

export const GridCellRowActions: FC<PropsWithChildren<GridCellRowActionsProps>> = ({
  isHidden,
  rowId,
  getPrevRowId,
  className,
  dragProps: { draggable, onDragStart, onDragEnd },
  ...props
}) => {
  const viewId = useViewId();
  const ref = useRef<HTMLDivElement | null>(null);
  const [openMenu, setOpenMenu] = useState(false);
  const handleInsertRecordBelow = useCallback(() => {
    void rowService.createRow(viewId, {
      startRowId: rowId,
    });
  }, [viewId, rowId]);

  const handleOpenMenu = () => {
    setOpenMenu(true);
  };

  const handleCloseMenu = () => {
    setOpenMenu(false);
  };

  if (isHidden) return null;

  return (
    <div ref={ref} className={`relative inline-flex items-center ${className || ''}`} {...props}>
      <Tooltip placement='top' title={t('grid.row.add')}>
        <IconButton onClick={handleInsertRecordBelow}>
          <AddSvg />
        </IconButton>
      </Tooltip>
      <Tooltip placement='top' title={t('grid.row.dragAndClick')}>
        <IconButton
          onClick={handleOpenMenu}
          className='mx-1 cursor-grab active:cursor-grabbing'
          draggable={draggable}
          onDragStart={onDragStart}
          onDragEnd={onDragEnd}
        >
          <DragSvg className='-mx-1' />
        </IconButton>
      </Tooltip>
      <Popover
        open={openMenu}
        onClose={handleCloseMenu}
        transformOrigin={{
          vertical: 'center',
          horizontal: 'left',
        }}
        anchorOrigin={{
          vertical: 'center',
          horizontal: 'right',
        }}
        container={ref.current}
        anchorEl={ref.current}
      >
        <GridCellRowMenu onClickItem={() => handleCloseMenu} rowId={rowId} getPrevRowId={getPrevRowId} />
      </Popover>
    </div>
  );
};
