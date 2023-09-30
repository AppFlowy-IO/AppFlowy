import React from 'react';
import BlockSideToolbar from '$app/components/document/BlockSideToolbar';

function BlockOverlay({ id }: { id: string }) {
  return (
    <div className='block-overlay'>
      <BlockSideToolbar id={id} />
    </div>
  );
}

export default BlockOverlay;
