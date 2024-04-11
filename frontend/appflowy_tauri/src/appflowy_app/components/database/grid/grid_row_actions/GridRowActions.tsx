import React, { useCallback, useState } from 'react';
import { IconButton, Tooltip } from '@mui/material';
import { ReactComponent as AddSvg } from '$app/assets/add.svg';
import { GRID_ACTIONS_WIDTH } from '$app/components/database/grid/constants';
import { rowService } from '$app/application/database';
import { useViewId } from '$app/hooks';
import { GridRowDragButton, GridRowMenu, toggleProperty } from '$app/components/database/grid/grid_row_actions';
import { OrderObjectPositionTypePB } from '@/services/backend';
import { useSortsCount } from '$app/components/database';
import { useTranslation } from 'react-i18next';
import { deleteAllSorts } from '$app/application/database/sort/sort_service';

export function GridRowActions({
  rowId,
  rowTop,
  containerRef,
  getScrollElement,
  onOpenConfirm,
}: {
  onOpenConfirm: (onOk: () => Promise<void>, onCancel: () => void) => void;
  rowId?: string;
  rowTop?: string;
  containerRef: React.MutableRefObject<HTMLDivElement | null>;
  getScrollElement: () => HTMLDivElement | null;
}) {
  const { t } = useTranslation();
  const viewId = useViewId();
  const sortsCount = useSortsCount();
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
    if (containerRef.current && menuRowId) {
      toggleProperty(containerRef.current, menuRowId, false);
    }
  }, [containerRef, menuRowId]);

  const handleInsertRecordBelow = useCallback(
    async (rowId: string) => {
      await rowService.createRow(viewId, {
        position: OrderObjectPositionTypePB.After,
        rowId: rowId,
      });
      handleCloseMenu();
    },
    [viewId, handleCloseMenu]
  );

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
          className={'z-10 flex w-full items-center justify-end py-[3px]'}
        >
          <Tooltip placement='top' disableInteractive={true} title={t('grid.row.add')}>
            <IconButton
              size={'small'}
              className={'h-5 w-5'}
              onClick={() => {
                if (sortsCount > 0) {
                  onOpenConfirm(
                    async () => {
                      await deleteAllSorts(viewId);
                      void handleInsertRecordBelow(rowId);
                    },
                    () => {
                      void handleInsertRecordBelow(rowId);
                    }
                  );
                } else {
                  void handleInsertRecordBelow(rowId);
                }
              }}
            >
              <AddSvg />
            </IconButton>
          </Tooltip>
          <GridRowDragButton
            getScrollElement={getScrollElement}
            rowId={rowId}
            containerRef={containerRef}
            onClick={handleOpenMenu}
            onOpenConfirm={onOpenConfirm}
          />
        </div>
      )}
      {menuRowId && (
        <GridRowMenu
          open={openMenu}
          onOpenConfirm={onOpenConfirm}
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
