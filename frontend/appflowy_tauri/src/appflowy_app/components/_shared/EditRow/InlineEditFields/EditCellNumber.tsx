import { CellController } from '$app/stores/effects/database/cell/cell_controller';
import { useEffect, useState } from 'react';

export const EditCellNumber = ({
  data,
  cellController,
}: {
  data: string | undefined;
  cellController: CellController<any, any>;
}) => {
  const [value, setValue] = useState('');

  useEffect(() => {
    setValue(data ?? '');
  }, [data]);

  const save = async () => {
    await cellController?.saveCellData(value);
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
