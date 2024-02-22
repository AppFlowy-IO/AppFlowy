import React, { useCallback, useState } from 'react';
import { IconButton, Tooltip } from '@mui/material';
import { ReactComponent as AddSvg } from '$app/assets/add.svg';
import { GRID_ACTIONS_WIDTH } from '$app/components/database/grid/constants';
import { rowService } from '$app/application/database';
import { useViewId } from '$app/hooks';
import { GridRowDragButton, GridRowMenu, toggleProperty } from '$app/components/database/grid/grid_row_actions';
import { OrderObjectPositionTypePB } from '@/services/backend';
import { useSortsCount } from '$app/components/database';
import DeleteConfirmDialog from '$app/components/_shared/confirm_dialog/DeleteConfirmDialog';
import { useTranslation } from 'react-i18next';
import { deleteAllSorts } from '$app/application/database/sort/sort_service';

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
  const { t } = useTranslation();
  const viewId = useViewId();
  const sortsCount = useSortsCount();
  const [openConfirm, setOpenConfirm] = useState(false);
  const [confirmRowId, setConfirmRowId] = useState<string | undefined>();
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
          className={'z-10 flex w-full items-center justify-end'}
        >
          <Tooltip placement='top' title={t('grid.row.add')}>
            <IconButton
              onClick={() => {
                setConfirmRowId(rowId);
                if (sortsCount > 0) {
                  setOpenConfirm(true);
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
          />
        </div>
      )}
      {menuRowId && (
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
      {openConfirm && (
        <DeleteConfirmDialog
          open={openConfirm}
          title={t('grid.removeSorting')}
          onOk={async () => {
            if (!confirmRowId) return;
            await deleteAllSorts(viewId);
            await handleInsertRecordBelow(confirmRowId);
          }}
          onClose={() => {
            setOpenConfirm(false);
          }}
          onCancel={() => {
            if (!confirmRowId) return;
            void handleInsertRecordBelow(confirmRowId);
          }}
          okText={t('button.remove')}
          cancelText={t('button.dontRemove')}
        />
      )}
    </>
  );
}

export default GridRowActions;
