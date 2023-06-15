import { useAppSelector } from '$app/stores/store';
import { BlockType, NestedBlock } from '$app/interfaces/document';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';

export function useNumberedListBlock(node: NestedBlock<BlockType.NumberedListBlock>) {
  const { docId } = useSubscribeDocument();

  // Find the last index of the previous blocks
  const prevNumberedIndex = useAppSelector((state) => {
    const documentState = state['document'][docId];
    const nodes = documentState.nodes;
    const children = documentState.children;
    // The parent must be existed
    const parent = nodes[node.parent!];
    const siblings = children[parent.children];
    const index = siblings.indexOf(node.id);
    if (index === 0) return 0;
    const prevNodeIds = siblings.slice(0, index);
    // The index is distance from last block to the last non-numbered-list block
    const lastIndex = prevNodeIds.reverse().findIndex((id) => {
      return nodes[id].type !== BlockType.NumberedListBlock;
    });
    if (lastIndex === -1) return prevNodeIds.length;
    return lastIndex;
  });

  return {
    index: prevNumberedIndex + 1,
  };
}
