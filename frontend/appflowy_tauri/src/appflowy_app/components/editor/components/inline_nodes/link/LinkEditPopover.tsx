import React from 'react';
import Popover from '@mui/material/Popover';
import { PopoverCommonProps } from '$app/components/editor/components/tools/popover';

import usePopoverAutoPosition from '$app/components/_shared/popover/Popover.hooks';
import { PopoverOrigin } from '@mui/material/Popover/Popover';
import LinkEditContent from '$app/components/editor/components/inline_nodes/link/LinkEditContent';

const initialAnchorOrigin: PopoverOrigin = {
  vertical: 'bottom',
  horizontal: 'center',
};

const initialTransformOrigin: PopoverOrigin = {
  vertical: 'top',
  horizontal: 'center',
};

export function LinkEditPopover({
  defaultHref,
  open,
  onClose,
  anchorPosition,
  anchorReference,
}: {
  defaultHref: string;
  open: boolean;
  onClose: () => void;
  anchorPosition?: { top: number; left: number; height: number };
  anchorReference?: 'anchorPosition' | 'anchorEl';
}) {
  const {
    paperHeight,
    anchorPosition: newAnchorPosition,
    transformOrigin,
    anchorOrigin,
  } = usePopoverAutoPosition({
    anchorPosition,
    open,
    initialAnchorOrigin,
    initialTransformOrigin,
    initialPaperWidth: 340,
    initialPaperHeight: 200,
  });

  return (
    <Popover
      {...PopoverCommonProps}
      open={open}
      anchorPosition={newAnchorPosition}
      anchorReference={anchorReference}
      onClose={() => {
        onClose();
      }}
      transformOrigin={transformOrigin}
      anchorOrigin={anchorOrigin}
      onMouseDown={(e) => e.stopPropagation()}
    >
      <div
        style={{
          maxHeight: paperHeight,
        }}
        className='flex select-none flex-col p-4'
      >
        <LinkEditContent defaultHref={defaultHref} onClose={onClose} />
      </div>
    </Popover>
  );
}
