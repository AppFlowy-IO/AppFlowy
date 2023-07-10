import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { calcToolbarPosition } from '$app/utils/document/toolbar';
import { getNode } from '$app/utils/document/node';
import { debounce } from '$app/utils/tool';
import { useSubscribeCaret } from '$app/components/document/_shared/SubscribeSelection.hooks';

export function useMenuStyle(container: HTMLDivElement) {
  const ref = useRef<HTMLDivElement | null>(null);

  const caret = useSubscribeCaret();
  const id = caret?.id;

  const [isScrolling, setIsScrolling] = useState(false);

  const reCalculatePosition = useCallback(() => {
    const el = ref.current;

    if (!el || !id) return;

    const node = getNode(id);

    if (!node) return;
    const position = calcToolbarPosition(el, node, container);

    if (!position) {
      el.style.opacity = '0';
      el.style.pointerEvents = 'none';
    } else {
      el.style.opacity = '1';
      el.style.pointerEvents = 'auto';
      el.style.top = position.top + 'px';
      el.style.left = position.left + 'px';
    }
  }, [container, id]);

  useEffect(() => {
    // recalculating toolbar position when scrolling is finished
    if (isScrolling) return;
    reCalculatePosition();
  }, [container, id, isScrolling, reCalculatePosition]);

  const debounceScrollEnd = useMemo(() => {
    return debounce(() => {
      // set isScrolling to false after 20ms
      setIsScrolling(false);
    }, 20);
  }, []);

  useEffect(() => {
    const handleScroll = () => {
      setIsScrolling(true);
      debounceScrollEnd();
    };

    container.addEventListener('scroll', handleScroll);
    return () => {
      debounceScrollEnd.cancel();
      container.removeEventListener('scroll', handleScroll);
    };
  }, [container, debounceScrollEnd]);

  return {
    ref,
    id,
  };
}
