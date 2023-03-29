import Picker from 'react-tailwindcss-datepicker';
import { DateValueType } from 'react-tailwindcss-datepicker/dist/types';
import { useRef, useState } from 'react';
import { DateCellDataPB } from '@/services/backend';
import { CellController } from '$app/stores/effects/database/cell/cell_controller';

export const EditCellDate = ({
  data,
  cellController,
  onEditClick,
}: {
  data?: DateCellDataPB;
  cellController: CellController<any, any>;
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
      {data?.date || ''}
    </div>
  );
};
