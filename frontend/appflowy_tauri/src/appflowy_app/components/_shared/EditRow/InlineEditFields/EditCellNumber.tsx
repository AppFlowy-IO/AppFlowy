import { useEffect, useState } from 'react';

export const EditCellNumber = ({ data, onSave }: { data: string | undefined; onSave: (value: string) => void }) => {
  const [value, setValue] = useState('');

  useEffect(() => {
    setValue(data ?? '');
  }, [data]);

  // const save = async () => {
  //   await cellController?.saveCellData(value);
  // };

  return (
    <input
      value={value}
      onChange={(e) => setValue(e.target.value)}
      onBlur={() => onSave(value)}
      className={'w-full px-4 py-1'}
    ></input>
  );
};
