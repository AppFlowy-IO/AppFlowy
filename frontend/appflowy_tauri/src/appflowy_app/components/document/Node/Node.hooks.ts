import { useRef } from 'react';
import { useSubscribeNode } from '../_shared/SubscribeNode.hooks';

export function useNode(id: string) {
  const { node, childIds, isSelected } = useSubscribeNode(id);
  const ref = useRef<HTMLDivElement>(null);

  return {
    ref,
    node,
    childIds,
    isSelected,
  };
}
