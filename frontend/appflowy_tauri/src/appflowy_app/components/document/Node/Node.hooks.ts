
import { useSubscribeNode } from '../_shared/SubscribeNode.hooks';

export function useNode(id: string) {
  const { node, childIds } = useSubscribeNode(id);

  return {
    node,
    childIds,
  }
}