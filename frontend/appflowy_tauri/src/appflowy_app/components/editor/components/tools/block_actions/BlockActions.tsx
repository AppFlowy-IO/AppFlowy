import React from 'react';

import { Element } from 'slate';
import AddBlockBelow from '$app/components/editor/components/tools/block_actions/AddBlockBelow';
import BlockMenu from '$app/components/editor/components/tools/block_actions/BlockMenu';

export function BlockActions({ node, onSelectedBlock }: { node?: Element; onSelectedBlock: (blockId: string) => void }) {
  return (
    <>
      <AddBlockBelow node={node} />
      <BlockMenu node={node} onSelectedBlock={onSelectedBlock} />
    </>
  );
}

export default BlockActions;
