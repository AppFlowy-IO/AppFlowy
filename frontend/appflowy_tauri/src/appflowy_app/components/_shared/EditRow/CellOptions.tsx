import { SelectOptionCellDataPB } from '@/services/backend';
import { getBgColor } from '$app/components/_shared/getColor';
import { useRef } from 'react';

export const CellOptions = ({
  data,
  onEditClick,
}: {
  data: SelectOptionCellDataPB | undefined;
  onEditClick: (left: number, top: number) => void;
}) => {
  const ref = useRef<HTMLDivElement>(null);

  const onClick = () => {
    if (!ref.current) return;
    const { left, top } = ref.current.getBoundingClientRect();
    onEditClick(left, top);
  };

  return (
    <div
      ref={ref}
      onClick={() => onClick()}
      className={'flex flex-wrap items-center gap-2 px-4 py-2 text-xs text-black'}
    >
      {data?.select_options?.map((option, index) => (
        <div className={`${getBgColor(option.color)} rounded px-2 py-0.5`} key={index}>
          {option?.name || ''}
        </div>
      )) || ''}
      &nbsp;
    </div>
  );
};
