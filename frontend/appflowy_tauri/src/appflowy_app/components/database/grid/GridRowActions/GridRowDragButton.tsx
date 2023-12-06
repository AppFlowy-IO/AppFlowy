import React from 'react';
import { useDraggableGridRow } from './GridRowActions.hooks';
import { IconButton, Tooltip } from '@mui/material';
import { ReactComponent as DragSvg } from '$app/assets/drag.svg';
import { useTranslation } from 'react-i18next';

function GridRowDragButton({
  rowId,
  containerRef,
  onClick,
  getScrollElement,
}: {
  rowId: string;
  onClick?: (e: React.MouseEvent<HTMLButtonElement>) => void;
  containerRef: React.MutableRefObject<HTMLDivElement | null>;
  getScrollElement: () => HTMLDivElement | null;
}) {
  const { t } = useTranslation();

  const { onDragStart } = useDraggableGridRow(rowId, containerRef, getScrollElement);

  return (
    <Tooltip placement='top' title={t('grid.row.dragAndClick')}>
      <IconButton
        onClick={onClick}
        draggable={true}
        onDragStart={onDragStart}
        className='mx-1 cursor-grab active:cursor-grabbing'
      >
        <DragSvg className='-mx-1' />
      </IconButton>
    </Tooltip>
  );
}

export default GridRowDragButton;
