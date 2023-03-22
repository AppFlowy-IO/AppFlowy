import { useEffect, useRef } from 'react';
import useOutsideClick from '../../_shared/useOutsideClick';

export const RenamePopup = ({
  value,
  onChange,
  onClose,
  className = '',
  top,
}: {
  value: string;
  onChange: (newTitle: string) => void;
  onClose: () => void;
  className?: string;
  top?: number;
}) => {
  const ref = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);
  useOutsideClick(ref, () => onClose && onClose());

  useEffect(() => {
    if (!inputRef || !inputRef.current) return;

    const { current: el } = inputRef;

    el.focus();
    el.selectionStart = 0;
    el.selectionEnd = el.value.length;
  }, [inputRef]);

  return (
    <div
      ref={ref}
      className={
        'absolute left-[50px] top-[40px] z-10 flex w-[300px] rounded bg-white py-1 px-1.5 shadow-md ' + className
      }
      style={{ top: `${top}px` }}
    >
      <input
        ref={inputRef}
        className={'border-shades-3 flex-1 rounded border bg-main-selector p-1'}
        value={value}
        onChange={(e) => onChange(e.target.value)}
      />
    </div>
  );
};
