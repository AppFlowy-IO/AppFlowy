import { Node } from '@/appflowy_app/stores/reducers/document/slice';
import { useAppSelector } from '@/appflowy_app/stores/store';
import { useMemo } from 'react';

export function useSubscribeNode(id: string) {
  const node = useAppSelector<Node | undefined>(state => state.document.nodes[id]);
  const childIds = useAppSelector<string[] | undefined>(state => state.document.children[id]);

  const memoizedNode = useMemo(() => node, [node?.id, node?.data, node?.type]);
  const memoizedChildIds = useMemo(() => childIds, [JSON.stringify(childIds)]);

  return {
    node: memoizedNode,
    childIds: memoizedChildIds
  }
}