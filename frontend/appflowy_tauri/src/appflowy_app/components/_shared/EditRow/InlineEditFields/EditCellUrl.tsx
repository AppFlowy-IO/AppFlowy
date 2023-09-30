import { URLCellDataPB } from '@/services/backend';
import { useEffect, useState } from 'react';

export const EditCellUrl = ({ data, onSave }: { data: URLCellDataPB | undefined; onSave: (value: string) => void }) => {
  const [value, setValue] = useState('');

  useEffect(() => {
    setValue((data as URLCellDataPB)?.url ?? '');
  }, [data]);

  return (
    <input
      value={value}
      onChange={(e) => setValue(e.target.value)}
      onBlur={() => onSave(value)}
      className={'w-full px-4 py-1'}
    ></input>
  );
};
