import { store, useAppSelector } from '@/appflowy_app/stores/store';
import { createContext, useContext, useMemo } from 'react';
import { Node } from '$app/interfaces/document';
import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';

/**
 * Subscribe node information
 * @param id
 */
export function useSubscribeNode(id: string) {
  const controller = useContext(DocumentControllerContext);
  const docId = controller.documentId;
  const node = useAppSelector<Node>((state) => {
    return state.document[docId].nodes[id];
  });

  const childIds = useAppSelector<string[] | undefined>((state) => {
    const childrenId = state.document[docId].nodes[id]?.children;
    if (!childrenId) return;
    return state.document[docId].children[childrenId];
  });

  const isSelected = useAppSelector<boolean>((state) => {
    return state.documentRectSelection[docId]?.selection.includes(id) || false;
  });

  // Memoize the node and its children
  // So that the component will not be re-rendered when other node is changed
  // It very important for performance
  const memoizedNode = useMemo(() => node, [JSON.stringify(node)]);
  const memoizedChildIds = useMemo(() => childIds, [JSON.stringify(childIds)]);

  return {
    node: memoizedNode,
    childIds: memoizedChildIds,
    isSelected,
  };
}

export function getBlock(docId: string, id: string) {
  return store.getState().document[docId].nodes[id];
}

export const NodeIdContext = createContext<string>('');
