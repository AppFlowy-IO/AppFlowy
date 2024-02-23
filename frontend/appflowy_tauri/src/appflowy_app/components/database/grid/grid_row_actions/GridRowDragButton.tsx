import React, { useEffect, useState } from 'react';
import { useDraggableGridRow } from './GridRowActions.hooks';
import { IconButton, Tooltip } from '@mui/material';
import { ReactComponent as DragSvg } from '$app/assets/drag.svg';
import { useTranslation } from 'react-i18next';

export function GridRowDragButton({
  rowId,
  containerRef,
  onClick,
  getScrollElement,
  onOpenConfirm,
}: {
  onOpenConfirm: (onOk: () => Promise<void>, onCancel: () => void) => void;
  rowId: string;
  onClick?: (e: React.MouseEvent<HTMLButtonElement>) => void;
  containerRef: React.MutableRefObject<HTMLDivElement | null>;
  getScrollElement: () => HTMLDivElement | null;
}) {
  const { t } = useTranslation();

  const [openTooltip, setOpenTooltip] = useState(false);
  const { onDragStart, isDragging } = useDraggableGridRow(rowId, containerRef, getScrollElement, onOpenConfirm);

  useEffect(() => {
    if (isDragging) {
      setOpenTooltip(false);
    }
  }, [isDragging]);

  return (
    <>
      <Tooltip
        open={openTooltip}
        onOpen={() => {
          setOpenTooltip(true);
        }}
        onClose={() => {
          setOpenTooltip(false);
        }}
        placement='top'
        disableInteractive={true}
        title={t('grid.row.dragAndClick')}
      >
        <IconButton
          size={'small'}
          onClick={onClick}
          draggable={true}
          onDragStart={onDragStart}
          className='mx-1 h-5  w-5 cursor-grab active:cursor-grabbing'
        >
          <DragSvg className='-mx-1' />
        </IconButton>
      </Tooltip>
    </>
  );
}

export default GridRowDragButton;
