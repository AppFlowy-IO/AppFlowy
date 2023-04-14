import { useSubscribeNode } from '../_shared/SubscribeNode.hooks';
export function useDocumentTitle(id: string) {
  const { node } = useSubscribeNode(id);
  return {
    node,
  };
}
