import { BlockType } from '@/application/types';
import { Popover } from '@/components/_shared/popover';
import { usePopoverContext } from '@/components/editor/components/block-popover/BlockPopoverContext';
import FileBlockPopoverContent from '@/components/editor/components/block-popover/FileBlockPopoverContent';
import ImageBlockPopoverContent from '@/components/editor/components/block-popover/ImageBlockPopoverContent';
import React, { useMemo } from 'react';

function BlockPopover () {
  const {
    open,
    anchorEl,
    close,
    type,
    blockId,
  } = usePopoverContext();

  const content = useMemo(() => {
    if (!blockId) return;
    switch (type) {
      case BlockType.FileBlock:
        return <FileBlockPopoverContent blockId={blockId} />;
      case BlockType.ImageBlock:
        return <ImageBlockPopoverContent blockId={blockId} />;
      default:
        return null;
    }
  }, [type, blockId]);

  return <Popover
    open={open}
    onClose={close}
    anchorEl={anchorEl}
    transformOrigin={{
      vertical: 'top',
      horizontal: 'center',
    }}
    anchorOrigin={{
      vertical: 'bottom',
      horizontal: 'center',
    }}
  >
    {content}
  </Popover>;
}

export default BlockPopover;