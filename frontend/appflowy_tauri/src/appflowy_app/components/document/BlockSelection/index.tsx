import React from 'react';
import BlockRectSelection from '$app/components/document/BlockSelection/BlockRectSelection';
import { useBlockRangeSelection } from '$app/components/document/BlockSelection/BlockRangeSelection.hooks';
import { useNodesRect } from '$app/components/document/BlockSelection/NodesRect.hooks';

function BlockSelection({ container }: { container: HTMLDivElement }) {
  const { getIntersectedBlockIds } = useNodesRect(container);

  useBlockRangeSelection(container);
  return (
    <div className='appflowy-block-selection-overlay z-1 pointer-events-none fixed inset-0 overflow-hidden'>
      <BlockRectSelection getIntersectedBlockIds={getIntersectedBlockIds} container={container} />
    </div>
  );
}

export default React.memo(BlockSelection);
