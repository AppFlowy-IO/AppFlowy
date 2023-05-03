import { useAppSelector } from '$app/stores/store';
import { BlockType, NestedBlock } from '$app/interfaces/document';
import { useEffect, useMemo } from 'react';

export function useNumberedListBlock(node: NestedBlock<BlockType.NumberedListBlock>) {
  const prevNumberedIndex = useAppSelector((state) => {
    const nodes = state['document'].nodes;
    const children = state['document'].children;
    // The parent must be existed
    const parent = nodes[node.parent!];
    const siblings = children[parent.children];
    const index = siblings.indexOf(node.id);
    // listen the change of the previous node
    const prevNodeIds = siblings.slice(0, index);
    const prevNodeTypes = prevNodeIds.map((id) => nodes[id].type);

    if (index === 0) return 0;
    const numberedIndex = prevNodeTypes.reverse().findIndex((type) => {
      return type !== BlockType.NumberedListBlock;
    });
    if (numberedIndex === -1) return prevNodeTypes.length;
    return numberedIndex;
  });

  return {
    index: prevNumberedIndex + 1,
  };
}
