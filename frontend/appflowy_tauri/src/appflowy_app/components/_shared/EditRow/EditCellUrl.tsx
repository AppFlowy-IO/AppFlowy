import { URLCellDataPB } from '@/services/backend';
import { CellController } from '$app/stores/effects/database/cell/cell_controller';
import { useEffect, useState } from 'react';
import { URLCellController } from '$app/stores/effects/database/cell/controller_builder';

export const EditCellUrl = ({
  data,
  cellController,
}: {
  data: URLCellDataPB | undefined;
  cellController: CellController<any, any>;
}) => {
  const [value, setValue] = useState('');

  useEffect(() => {
    setValue((data as URLCellDataPB)?.url ?? '');
  }, [data]);

  const save = async () => {
    await (cellController as URLCellController)?.saveCellData(value);
  };

  return (
    <input
      value={value}
      onChange={(e) => setValue(e.target.value)}
      onBlur={() => save()}
      className={'w-full px-4 py-1'}
    ></input>
  );
};
