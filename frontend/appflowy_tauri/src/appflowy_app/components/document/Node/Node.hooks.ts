import { useEffect, useRef } from 'react';
import { useSubscribeNode } from '../_shared/SubscribeNode.hooks';
import { useAppDispatch } from '$app/stores/store';
import { documentActions } from '$app/stores/reducers/document/slice';

export function useNode(id: string) {
  const { node, childIds, isSelected } = useSubscribeNode(id);
  const ref = useRef<HTMLDivElement>(null);

  const dispatch = useAppDispatch();

  useEffect(() => {
    if (!ref.current) return;
    const rect = ref.current.getBoundingClientRect();

    const scrollContainer = document.querySelector('.doc-scroller-container') as HTMLDivElement;
    dispatch(
      documentActions.updateNodePosition({
        id,
        rect: {
          x: rect.x,
          y: rect.y + scrollContainer.scrollTop,
          height: rect.height,
          width: rect.width,
        },
      })
    );
  }, []);

  return {
    ref,
    node,
    childIds,
    isSelected,
  };
}
