import { Popover } from '@/components/_shared/popover';
import { usePopoverContext } from '@/components/editor/components/block-popover/BlockPopoverContext';
import React from 'react';

function BlockPopover () {
  const {
    open,
    anchorEl,
    close,
  } = usePopoverContext();

  return <Popover
    open={open}
    onClose={close}
    anchorEl={anchorEl}
  ></Popover>;
}

export default BlockPopover;