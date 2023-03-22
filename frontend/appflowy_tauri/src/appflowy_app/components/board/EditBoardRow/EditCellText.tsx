import { CellController } from '$app/stores/effects/database/cell/cell_controller';
import { useEffect, useState, KeyboardEvent, useMemo } from 'react';

export const EditCellText = ({ data, cellController }: { data: string; cellController: CellController<any, any> }) => {
  const [value, setValue] = useState('');
  const [contentRows, setContentRows] = useState(1);
  useEffect(() => {
    setValue(data);
  }, [data]);

  useEffect(() => {
    setContentRows(Math.max(1, (value || '').split('\n').length));
  }, [value]);

  const onTextFieldChange = async (v: string) => {
    setValue(v);
  };

  const save = async () => {
    await cellController?.saveCellData(value);
  };

  return (
    <textarea
      className={'h-full w-full resize-none'}
      rows={contentRows}
      value={value}
      onChange={(e) => onTextFieldChange(e.target.value)}
      onBlur={() => save()}
    />
  );
};
