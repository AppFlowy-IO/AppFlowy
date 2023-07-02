import { ReactNode, useEffect, useRef, useState } from 'react';
import useOutsideClick from '$app/components/_shared/useOutsideClick';

export const PopupWindow = ({
  children,
  className,
  onOutsideClick,
  left,
  top,
}: {
  children: ReactNode;
  className?: string;
  onOutsideClick: () => void;
  left: number;
  top: number;
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

      if (top + height > window.innerHeight) {
        // setAdjustedTop(window.innerHeight - height);
        setStickToBottom(true);
      } else {
        setStickToBottom(false);
        setAdjustedTop(top);
      }

      if (left + width > window.innerWidth) {
        // setAdjustedLeft(window.innerWidth - width);
        setStickToRight(true);
      } else {
        setStickToRight(false);
        setAdjustedLeft(left);
      }
    }).observe(ref.current);
  }, [ref, left, top]);

  return (
    <div
      ref={ref}
      className={
        'fixed z-10 rounded-lg bg-white shadow-md transition-opacity duration-300 ' +
        (adjustedTop === -100 && adjustedLeft === -100 ? 'opacity-0 ' : 'opacity-100 ') +
        (className ?? '')
      }
      style={{
        [stickToBottom ? 'bottom' : 'top']: `${stickToBottom ? '0' : adjustedTop}px`,
        [stickToRight ? 'right' : 'left']: `${stickToRight ? '0' : adjustedLeft}px`,
      }}
    >
      {children}
    </div>
  );
};
