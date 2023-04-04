import { useRef } from 'react';
import { DateCellDataPB } from '@/services/backend';

export const EditCellDate = ({
  data,
  onEditClick,
}: {
  data?: DateCellDataPB;
  onEditClick: (left: number, top: number) => void;
}) => {
  const ref = useRef<HTMLDivElement>(null);

  const onClick = () => {
    if (!ref.current) return;
    const { left, top } = ref.current.getBoundingClientRect();
    onEditClick(left, top);
  };

  return (
    <div ref={ref} onClick={() => onClick()} className={'px-4 py-2'}>
      {data?.date || <>&nbsp;</>}
    </div>
  );
};
