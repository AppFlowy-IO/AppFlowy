import { useRef } from 'react';
import useOutsideClick from '../../_shared/useOutsideClick';

export const RenamePopup = ({
  value,
  onChange,
  onClose,
}: {
  value: string;
  onChange: (newTitle: string) => void;
  onClose: () => void;
}) => {
  const ref = useRef<HTMLDivElement>(null);
  useOutsideClick(ref, () => onClose && onClose());

  return (
    <div
      ref={ref}
      className={'absolute z-10 left-[30px] top-[30px] w-[300px] bg-white shadow-md py-1 px-1.5 flex rounded '}
    >
      <input
        className={'rounded p-1 border bg-main-selector border-shades-3 flex-1'}
        value={value}
        onChange={(e) => onChange(e.target.value)}
      />
    </div>
  );
};
