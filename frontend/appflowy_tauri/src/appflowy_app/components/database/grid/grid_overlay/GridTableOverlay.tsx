import React, { useCallback, useEffect, useState } from 'react';
import {
  GridRowContextMenu,
  GridRowActions,
  useGridTableHoverState,
} from '$app/components/database/grid/grid_row_actions';
import DeleteConfirmDialog from '$app/components/_shared/confirm_dialog/DeleteConfirmDialog';
import { useTranslation } from 'react-i18next';

function GridTableOverlay({
  containerRef,
  getScrollElement,
}: {
  containerRef: React.MutableRefObject<HTMLDivElement | null>;
  getScrollElement: () => HTMLDivElement | null;
}) {
  const [hoverRowTop, setHoverRowTop] = useState<string | undefined>();

  const { t } = useTranslation();
  const [openConfirm, setOpenConfirm] = useState(false);
  const [confirmModalProps, setConfirmModalProps] = useState<
    | {
      onOk: () => Promise<void>;
      onCancel: () => void;
    }
    | undefined
  >(undefined);

  const { hoverRowId } = useGridTableHoverState(containerRef);

  const handleOpenConfirm = useCallback((onOk: () => Promise<void>, onCancel: () => void) => {
    setOpenConfirm(true);
    setConfirmModalProps({ onOk, onCancel });
  }, []);

  useEffect(() => {
    const container = containerRef.current;

    if (!container) return;

    const cell = container.querySelector(`[data-key="row:${hoverRowId}"]`);

    if (!cell) return;
    const top = (cell as HTMLDivElement).style.top;

    setHoverRowTop(top);
  }, [containerRef, hoverRowId]);

  return (
    <div className={'absolute left-0 top-0'}>
      <GridRowActions
        onOpenConfirm={handleOpenConfirm}
        getScrollElement={getScrollElement}
        containerRef={containerRef}
        rowId={hoverRowId}
        rowTop={hoverRowTop}
      />
      <GridRowContextMenu onOpenConfirm={handleOpenConfirm} containerRef={containerRef} hoverRowId={hoverRowId} />
      {openConfirm && (
        <DeleteConfirmDialog
          open={openConfirm}
          title={t('grid.sort.removeSorting')}
          okText={t('button.remove')}
          cancelText={t('button.dontRemove')}
          onClose={() => {
            setOpenConfirm(false);
          }}
          {...confirmModalProps}
        />
      )}
    </div>
  );
}

export default GridTableOverlay;
