import { useBlockSelection } from './BlockSelection.hooks';
import { BlockEditor } from '$app/block_editor';
import React from 'react';

function BlockSelection({
  container,
  blockEditor,
  onDragging,
}: {
  container: HTMLDivElement;
  blockEditor: BlockEditor;
  onDragging?: (_isDragging: boolean) => void;
}) {
  const { isDragging, style, ref } = useBlockSelection({
    container,
    blockEditor,
    onDragging,
  });

  return (
    <div ref={ref} className='appflowy-block-selection-overlay z-1 pointer-events-none fixed inset-0 overflow-hidden'>
      {isDragging ? <div className='z-99 absolute bg-[#00d5ff] opacity-25' style={style} /> : null}
    </div>
  );
}

export default React.memo(BlockSelection);
