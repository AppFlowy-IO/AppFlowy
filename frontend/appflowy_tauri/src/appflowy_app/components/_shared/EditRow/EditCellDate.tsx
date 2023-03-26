import Picker from 'react-tailwindcss-datepicker';
import { DateValueType } from 'react-tailwindcss-datepicker/dist/types';
import { useState } from 'react';
import { DateCellDataPB } from '@/services/backend';
import { CellController } from '$app/stores/effects/database/cell/cell_controller';

export const EditCellDate = ({
  data,
  cellController,
}: {
  data?: DateCellDataPB;
  cellController: CellController<any, any>;
}) => {
  const [value, setValue] = useState<DateValueType>({
    startDate: new Date(),
    endDate: new Date(),
  });

  const onChange = (v: DateValueType) => {
    console.log(v);
  };

  return (
    <div className={'px-4 py-2'}>
      <Picker value={value} onChange={onChange} useRange={false} asSingle={true}></Picker>;
    </div>
  );
};
