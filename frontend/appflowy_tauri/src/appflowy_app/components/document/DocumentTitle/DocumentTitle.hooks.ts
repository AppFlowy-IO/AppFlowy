import { useSubscribeNode } from '../_shared/SubscribeNode.hooks';
export function useDocumentTitle(id: string) {
  const { node, delta } = useSubscribeNode(id);
  return {
    node,
    delta
  }
}