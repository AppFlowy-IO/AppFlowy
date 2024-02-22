import React, { useCallback, useState } from 'react';
import { IconButton, Tooltip } from '@mui/material';
import { t } from 'i18next';
import { ReactComponent as AddSvg } from '$app/assets/add.svg';
import { GRID_ACTIONS_WIDTH } from '$app/components/database/grid/constants';
import { rowService } from '$app/application/database';
import { useViewId } from '$app/hooks';
import { GridRowDragButton, GridRowMenu, toggleProperty } from '$app/components/database/grid/grid_row_actions';
import { OrderObjectPositionTypePB } from '@/services/backend';

export function GridRowActions({
  rowId,
  rowTop,
  containerRef,
  getScrollElement,
}: {
  rowId?: string;
  rowTop?: string;
  containerRef: React.MutableRefObject<HTMLDivElement | null>;
  getScrollElement: () => HTMLDivElement | null;
}) {
  const viewId = useViewId();
  const [menuRowId, setMenuRowId] = useState<string | undefined>(undefined);
  const [menuPosition, setMenuPosition] = useState<
    | {
        top: number;
        left: number;
      }
    | undefined
  >(undefined);

  const openMenu = Boolean(menuPosition);

  const handleCloseMenu = useCallback(() => {
    setMenuPosition(undefined);
    setMenuRowId((prev) => {
      if (containerRef.current && prev) {
        toggleProperty(containerRef.current, prev, false);
      }

      return undefined;
    });
  }, [containerRef]);

  const handleInsertRecordBelow = useCallback(() => {
    void rowService.createRow(viewId, {
      position: OrderObjectPositionTypePB.After,
      rowId: rowId,
    });
    handleCloseMenu();
  }, [viewId, rowId, handleCloseMenu]);

  const handleOpenMenu = (e: React.MouseEvent) => {
    const target = e.target as HTMLButtonElement;
    const rect = target.getBoundingClientRect();

    if (containerRef.current && rowId) {
      toggleProperty(containerRef.current, rowId, true);
    }

    setMenuRowId(rowId);
    setMenuPosition({
      top: rect.top + rect.height / 2,
      left: rect.left + rect.width,
    });
  };

  return (
    <>
      {rowId && rowTop && (
        <div
          style={{
            position: 'absolute',
            top: rowTop,
            left: GRID_ACTIONS_WIDTH,
            transform: 'translateY(4px)',
          }}
          className={'z-10 flex w-full items-center justify-end'}
        >
          <Tooltip placement='top' title={t('grid.row.add')}>
            <IconButton onClick={handleInsertRecordBelow}>
              <AddSvg />
            </IconButton>
          </Tooltip>
          <GridRowDragButton
            getScrollElement={getScrollElement}
            rowId={rowId}
            containerRef={containerRef}
            onClick={handleOpenMenu}
          />
        </div>
      )}
      {openMenu && menuRowId && (
        <GridRowMenu
          open={openMenu}
          onClose={handleCloseMenu}
          transformOrigin={{
            vertical: 'center',
            horizontal: 'left',
          }}
          rowId={menuRowId}
          anchorReference={'anchorPosition'}
          anchorPosition={menuPosition}
        />
      )}
    </>
  );
}

export default GridRowActions;
