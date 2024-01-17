import React from 'react';

import { Element } from 'slate';
import AddBlockBelow from '$app/components/editor/components/tools/block_actions/AddBlockBelow';
import BlockMenu from '$app/components/editor/components/tools/block_actions/BlockMenu';

export function BlockActions({ node, setMenuVisible }: { node?: Element; setMenuVisible: (visible: boolean) => void }) {
  return (
    <>
      <AddBlockBelow node={node} />
      <BlockMenu setMenuVisible={setMenuVisible} node={node} />
    </>
  );
}

export default BlockActions;
