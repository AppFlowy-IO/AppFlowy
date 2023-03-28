import { DocumentData } from '$app/interfaces/document';
import { useSubscribeNode } from '../_shared/SubscribeNode.hooks';
import { useParseTree } from './Tree.hooks';

export function useRoot({ documentData }: { documentData: DocumentData }) {
  const { rootId } = documentData;

  useParseTree(documentData);

  const { node: rootNode, childIds: rootChildIds } = useSubscribeNode(rootId);

  return {
    node: rootNode,
    childIds: rootChildIds,
  };
}
