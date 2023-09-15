import { store, useAppSelector } from '@/appflowy_app/stores/store';
import { createContext, useMemo } from 'react';
import { Node } from '$app/interfaces/document';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';
import { DOCUMENT_NAME, RECT_RANGE_NAME } from '$app/constants/document/name';
import Delta from 'quill-delta';

/**
 * Subscribe node information
 * @param id
 */
export function useSubscribeNode(id: string) {
  const { docId } = useSubscribeDocument();

  const { node, delta } = useAppSelector<{
    node: Node;
    delta: string;
  }>((state) => {
    const documentState = state[DOCUMENT_NAME][docId];
    const node = documentState?.nodes[id];
    const externalId = node?.externalId;

    return {
      node,
      delta: externalId ? documentState?.deltaMap[externalId] : '',
    };
  });

  const childIds = useAppSelector<string[] | undefined>((state) => {
    const documentState = state[DOCUMENT_NAME][docId];

    if (!documentState) return;
    const childrenId = documentState.nodes[id]?.children;

    if (!childrenId) return;
    return documentState.children[childrenId];
  });

  const isSelected = useAppSelector<boolean>((state) => {
    return state[RECT_RANGE_NAME][docId]?.selection.includes(id) || false;
  });

  // Memoize the node and its children
  // So that the component will not be re-rendered when other node is changed
  // It very important for performance
  const memoizedNode = useMemo(() => node, [JSON.stringify(node)]);
  const memoizedChildIds = useMemo(() => childIds, [JSON.stringify(childIds)]);

  return {
    node: memoizedNode,
    childIds: memoizedChildIds,
    delta,
    isSelected,
  };
}

export function getBlock(docId: string, id: string) {
  return store.getState().document[docId]?.nodes[id];
}

export function getBlockDelta(docId: string, id: string) {
  const node = getBlock(docId, id);

  if (!node?.externalId) return;
  const deltaStr = store.getState().document[docId]?.deltaMap[node.externalId];
  const deltaJson = JSON.parse(deltaStr);
  const delta = new Delta(deltaJson);

  return delta;
}

export const NodeIdContext = createContext<string>('');
