import { useAppSelector } from '@/appflowy_app/stores/store';
import { useMemo, createContext } from 'react';
import { Node } from '$app/interfaces/document';
export const NodeContext = createContext<Node | null>(null);

/**
 * Subscribe to a node and its children
 * It will be change when the node or its children is changed
 * And it will not be change when other node is changed
 * @param id
 */
export function useSubscribeNode(id: string) {
  const node = useAppSelector<Node>((state) => state.document.nodes[id]);

  const childIds = useAppSelector<string[] | undefined>((state) => {
    const childrenId = state.document.nodes[id]?.children;
    if (!childrenId) return;
    return state.document.children[childrenId];
  });

  const isSelected = useAppSelector<boolean>((state) => {
    return state.rectSelection.selections?.includes(id) || false;
  });

  // Memoize the node and its children
  // So that the component will not be re-rendered when other node is changed
  // It very important for performance
  const memoizedNode = useMemo(
    () => node,
    [JSON.stringify(node)]
  );
  const memoizedChildIds = useMemo(() => childIds, [JSON.stringify(childIds)]);

  return {
    node: memoizedNode,
    childIds: memoizedChildIds,
    isSelected,
  };
}
