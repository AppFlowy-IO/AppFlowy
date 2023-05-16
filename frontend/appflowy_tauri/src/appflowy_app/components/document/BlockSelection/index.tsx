import React from 'react';
import BlockRectSelection from '$app/components/document/BlockSelection/BlockRectSelection';
import { useBlockRangeSelection } from '$app/components/document/BlockSelection/BlockRangeSelection.hooks';

function BlockSelection({ container }: { container: HTMLDivElement }) {
  useBlockRangeSelection(container);
  return (
    <div className='appflowy-block-selection-overlay z-1 pointer-events-none fixed inset-0 overflow-hidden'>
      <BlockRectSelection container={container} />
    </div>
  );
}

export default React.memo(BlockSelection);
