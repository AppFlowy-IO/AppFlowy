import { MouseEventHandler, useRef } from 'react';
import { DateCellDataPB } from '@/services/backend';

export const EditCellDate = ({
  data,
  onEditClick,
}: {
  data?: DateCellDataPB;
  onEditClick: (left: number, top: number) => void;
}) => {
  const ref = useRef<HTMLDivElement>(null);

  const onClick: MouseEventHandler = () => {
    if (!ref.current) return;
    const { left, top } = ref.current.getBoundingClientRect();
    onEditClick(left, top);
  };

  return (
    <div ref={ref} onClick={onClick} className={'w-full px-4 py-1'}>
      {data?.date}&nbsp;
    </div>
  );
};
