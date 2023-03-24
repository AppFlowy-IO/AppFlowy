import React from 'react';
import { useBlockSideTools } from './BlockSideTools.hooks';
import { BlockEditor } from '@/appflowy_app/block_editor';
import AddIcon from '@mui/icons-material/Add';
import DragIndicatorIcon from '@mui/icons-material/DragIndicator';
import Portal from '../BlockPortal';
import { IconButton } from '@mui/material';

const sx = { height: 24, width: 24 };

export default function BlockSideTools(props: { container: HTMLDivElement; blockEditor: BlockEditor }) {
  const { hoverBlock, ref } = useBlockSideTools(props);

  if (!hoverBlock) return null;
  return (
    <Portal blockId={hoverBlock}>
      <div
        ref={ref}
        style={{
          opacity: 0,
        }}
        className='z-1 absolute left-[-50px] inline-flex h-[calc(1.5em_+_3px)] transition-opacity duration-500'
        onMouseDown={(e) => {
          // prevent toolbar from taking focus away from editor
          e.preventDefault();
        }}
      >
        <IconButton sx={sx}>
          <AddIcon />
        </IconButton>
        <IconButton sx={sx}>
          <DragIndicatorIcon />
        </IconButton>
      </div>
    </Portal>
  );
}
