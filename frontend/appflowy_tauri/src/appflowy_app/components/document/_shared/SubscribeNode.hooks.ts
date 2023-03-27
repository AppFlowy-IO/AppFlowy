import { Node } from '@/appflowy_app/stores/reducers/document/slice';
import { useAppSelector } from '@/appflowy_app/stores/store';
import { useMemo } from 'react';
import { TextDelta } from '@/appflowy_app/interfaces/document';

/**
 * Subscribe to a node and its children
 * It will be change when the node or its children is changed
 * And it will not be change when other node is changed
 * @param id
 */
export function useSubscribeNode(id: string) {
  const node = useAppSelector<Node>(state => state.document.nodes[id]);

  const childIds = useAppSelector<string[] | undefined>(state => {
    const childrenId = state.document.nodes[id]?.children;
    if (!childrenId) return;
    return state.document.children[childrenId];
  });

  const delta = useAppSelector<TextDelta[] | undefined>(state => {
    const externalType = state.document.nodes[id]?.externalType;
    if (externalType !== 'text') return;
    const deltaId = state.document.nodes[id]?.externalId;
    if (!deltaId) return;
    return state.document.delta[deltaId];
  });

  const isSelected = useAppSelector<boolean>(state => {
    return state.document.selections?.includes(id) || false;
  });

  // Memoize the node and its children
  // So that the component will not be re-rendered when other node is changed
  // It very important for performance
  const memoizedNode = useMemo(() => node, [node?.id, node?.data, node?.parent, node?.type, node?.children]);
  const memoizedChildIds = useMemo(() => childIds, [JSON.stringify(childIds)]);
  const memoizedDelta = useMemo(() => delta, [JSON.stringify(delta)]);
  
  return {
    node: memoizedNode,
    childIds: memoizedChildIds,
    delta: memoizedDelta,
    isSelected
  };
}