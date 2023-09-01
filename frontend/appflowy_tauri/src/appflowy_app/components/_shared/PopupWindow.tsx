import { CSSProperties, ReactNode, useEffect, useRef, useState } from 'react';
import useOutsideClick from '$app/components/_shared/useOutsideClick';

export const PopupWindow = ({
  children,
  className,
  onOutsideClick,
  left,
  top,
  style,
}: {
  children: ReactNode;
  className?: string;
  onOutsideClick: () => void;
  left: number;
  top: number;
  style?: CSSProperties;
}) => {
  const ref = useRef<HTMLDivElement>(null);

  useOutsideClick(ref, onOutsideClick);

  const [adjustedTop, setAdjustedTop] = useState(-100);
  const [adjustedLeft, setAdjustedLeft] = useState(-100);
  const [stickToBottom, setStickToBottom] = useState(false);
  const [stickToRight, setStickToRight] = useState(false);

  useEffect(() => {
    if (!ref.current) return;

    new ResizeObserver(() => {
      if (!ref.current) return;
      const { height, width } = ref.current.getBoundingClientRect();

      setAdjustedTop(top);
      if (top + height > window.innerHeight) {
        setStickToBottom(true);
      } else {
        setStickToBottom(false);
      }

      setAdjustedLeft(left);
      if (left + width > window.innerWidth) {
        setStickToRight(true);
      } else {
        setStickToRight(false);
      }
    }).observe(ref.current);
  }, [ref, left, top]);

  return (
    <div
      ref={ref}
      className={
        'fixed z-10 rounded-lg bg-bg-body shadow-md transition-opacity duration-300 ' +
        (adjustedTop === -100 && adjustedLeft === -100 ? 'opacity-0 ' : 'opacity-100 ') +
        (className ?? '')
      }
      style={{
        [stickToBottom ? 'bottom' : 'top']: `${stickToBottom ? '0' : adjustedTop}px`,
        [stickToRight ? 'right' : 'left']: `${stickToRight ? '0' : adjustedLeft}px`,
        ...style,
      }}
    >
      {children}
    </div>
  );
};
