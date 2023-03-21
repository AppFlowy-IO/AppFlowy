import { useEffect, useState, useRef, useContext } from 'react';

import { TreeNode } from '@/appflowy_app/block_editor/view/tree_node';
import { BlockContext } from '$app/utils/block';

export function useBlockComponent({
  node
}: {
  node: TreeNode
}) {
  const { blockEditor } = useContext(BlockContext);

  const [version, forceUpdate] = useState<number>(0);
  const myRef = useRef<HTMLDivElement | null>(null);

  const isSelected = blockEditor?.renderTree.isSelected(node.id);

  useEffect(() => {
    if (!myRef.current) {
      return;
    }
    const observe = blockEditor?.renderTree.observeBlock(myRef.current);
    node.registerUpdate(() => forceUpdate((prev) => prev + 1));

    return () => {
      node.unregisterUpdate();
      observe?.unobserve();
    };
  }, []);
  return {
    version,
    myRef,
    isSelected,
    className: `relative my-[1px] px-1`
  }
}
