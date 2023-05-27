import { SelectOptionCellDataPB } from '@/services/backend';
import { getBgColor } from '$app/components/_shared/getColor';
import { MouseEventHandler, useRef } from 'react';

export const CellOptions = ({
  data,
  onEditClick,
}: {
  data: SelectOptionCellDataPB | undefined;
  onEditClick: (left: number, top: number) => void;
}) => {
  const ref = useRef<HTMLDivElement>(null);

  const onClick: MouseEventHandler = () => {
    if (!ref.current) return;
    const { left, top } = ref.current.getBoundingClientRect();
    onEditClick(left, top);
  };

  return (
    <div ref={ref} onClick={onClick} className={'flex w-full flex-wrap items-center gap-2 px-4 py-1 text-xs text-black'}>
      {data?.select_options?.map((option, index) => (
        <div className={`${getBgColor(option.color)} rounded px-2 py-0.5`} key={index}>
          {option?.name ?? ''}
        </div>
      ))}
      &nbsp;
    </div>
  );
};
