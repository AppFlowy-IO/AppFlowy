import React from 'react';
import GridCellRowMenu from '$app/components/database/grid/GridRow/GridCellRow/GridCellRowMenu';
import Popover from '@mui/material/Popover';

interface Props {
  open: boolean;
  onClose: () => void;
  anchorPosition?: {
    top: number;
    left: number;
  };
  rowId: string;
  getPrevRowId: (id: string) => string | null;
}

function GridCellRowContextMenu({ open, anchorPosition, onClose, rowId, getPrevRowId }: Props) {
  return (
    <Popover
      open={open}
      onClose={onClose}
      anchorPosition={anchorPosition}
      anchorReference={'anchorPosition'}
      transformOrigin={{ vertical: 'top', horizontal: 'left' }}
    >
      <GridCellRowMenu
        rowId={rowId}
        getPrevRowId={getPrevRowId}
        onClickItem={() => {
          onClose();
        }}
      />
    </Popover>
  );
}

export default GridCellRowContextMenu;
