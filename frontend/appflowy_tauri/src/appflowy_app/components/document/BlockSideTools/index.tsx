import React from 'react';
import { useBlockSideTools } from './BlockSideTools.hooks';
import AddIcon from '@mui/icons-material/Add';
import DragIndicatorIcon from '@mui/icons-material/DragIndicator';
import Portal from '../BlockPortal';
import { IconButton } from '@mui/material';

const sx = { height: 24, width: 24 };

export default function BlockSideTools(props: { container: HTMLDivElement }) {
  const { nodeId, ref, handleAddClick } = useBlockSideTools(props);

  if (!nodeId) return null;
  return (
    <Portal blockId={nodeId}>
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
        <IconButton onClick={() => handleAddClick()} sx={sx}>
          <AddIcon />
        </IconButton>
        <IconButton sx={sx}>
          <DragIndicatorIcon />
        </IconButton>
      </div>
    </Portal>
  );
}
