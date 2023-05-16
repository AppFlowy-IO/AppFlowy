import { useEffect, useRef, useState } from 'react';
import { calcToolbarPosition } from '$app/utils/document/blocks/text/toolbar';
import { useAppSelector } from '$app/stores/store';

export function useMenuStyle(container: HTMLDivElement) {
  const ref = useRef<HTMLDivElement | null>(null);
  const range = useAppSelector((state) => state.documentRangeSelection);

  const [scrollTop, setScrollTop] = useState(container.scrollTop);
  useEffect(() => {
    const el = ref.current;
    if (!el) return;

    const id = range.focus?.id;
    if (!id) return;

    const position = calcToolbarPosition(el);

    if (!position) {
      el.style.opacity = '0';
      el.style.pointerEvents = 'none';
    } else {
      el.style.opacity = '1';
      el.style.pointerEvents = 'auto';
      el.style.top = position.top;
      el.style.left = position.left;
    }
  });

  useEffect(() => {
    const handleScroll = () => {
      setScrollTop(container.scrollTop);
    };
    container.addEventListener('scroll', handleScroll);
    return () => {
      container.removeEventListener('scroll', handleScroll);
    };
  }, [container]);

  return {
    ref,
  };
}
