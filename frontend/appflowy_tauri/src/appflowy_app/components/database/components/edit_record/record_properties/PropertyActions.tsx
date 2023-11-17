import React, { forwardRef } from 'react';
import { t } from 'i18next';
import { IconButton, Tooltip } from '@mui/material';
import { ReactComponent as DragSvg } from '$app/assets/drag.svg';

interface Props {
  onOpenMenu: () => void;
}

export default forwardRef<HTMLDivElement, Props>(function PropertyActions({ onOpenMenu }, ref) {
  return (
    <div ref={ref} className={`absolute left-[-30px] flex h-full items-center `}>
      <Tooltip placement='top' title={t('grid.row.dragAndClick')}>
        <IconButton onClick={onOpenMenu} className='mx-1 cursor-grab active:cursor-grabbing'>
          <DragSvg />
        </IconButton>
      </Tooltip>
    </div>
  );
});
