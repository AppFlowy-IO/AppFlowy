import { useBlockSelection } from './BlockSelection.hooks';
import { BlockEditor } from '$app/block_editor';
import React from 'react';

function BlockSelection({ container, blockEditor }: { container: HTMLDivElement; blockEditor: BlockEditor }) {
  const { isDragging, style } = useBlockSelection({
    container,
    blockEditor,
  });

  return (
    <div className='appflowy-block-selection-overlay z-1 pointer-events-none fixed inset-0 overflow-hidden'>
      {isDragging ? <div className='z-99 absolute bg-[#00d5ff] opacity-25' style={style} /> : null}
    </div>
  );
}

export default React.memo(BlockSelection);
