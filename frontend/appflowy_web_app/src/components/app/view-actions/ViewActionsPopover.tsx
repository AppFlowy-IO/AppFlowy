import React, { useMemo } from 'react';
import AddPageActions from '@/components/app/view-actions/AddPageActions';
import MoreSpaceActions from '@/components/app/view-actions/MoreSpaceActions';
import MorePageActions from '@/components/app/view-actions/MorePageActions';
import { Popover } from '@/components/_shared/popover';
import { PopoverProps } from '@mui/material/Popover';
import { View } from '@/application/types';

const popoverProps: Partial<PopoverProps> = {
  transformOrigin: {
    vertical: 'top',
    horizontal: 'left',
  },
  anchorOrigin: {
    vertical: 'bottom',
    horizontal: 'left',
  },
};

function ViewActionsPopover({
  popoverType,
  anchorPosition,
  view,
  onClose,
}: {
  view?: View;
  onClose: () => void;
  popoverType?: {
    category: 'space' | 'page';
    type: 'more' | 'add';
  },
  anchorPosition?: {
    top: number;
    left: number;
  }
}) {

  const open = Boolean(anchorPosition);

  const popoverContent = useMemo(() => {
    if (!popoverType || !view) return null;

    if (popoverType.type === 'add') {
      return <AddPageActions
        onClose={onClose}
        view={view}
      />;
    }

    if (popoverType.category === 'space') {
      return <MoreSpaceActions
        onClose={onClose}
        view={view}
      />;
    } else {
      return <MorePageActions
        view={view}
        onClose={onClose}
      />;
    }
  }, [onClose, popoverType, view]);

  return (
    <Popover
      {...popoverProps}
      open={open}
      anchorPosition={anchorPosition}
      keepMounted={true}
      onClose={onClose}
      anchorReference={'anchorPosition'}
      sx={{
        '& .MuiPopover-paper': {
          margin: '10px 0',
        },
      }}
    >
      {popoverContent}
    </Popover>
  );
}

export default ViewActionsPopover;