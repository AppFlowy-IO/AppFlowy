import { DocumentData } from '$app/interfaces/document';
import { useSubscribeNode } from '../_shared/SubscribeNode.hooks';

export function useRoot({ documentData }: { documentData: DocumentData }) {
  const { rootId } = documentData;

  const { node: rootNode, childIds: rootChildIds } = useSubscribeNode(rootId);

  return {
    node: rootNode,
    childIds: rootChildIds,
  };
}
