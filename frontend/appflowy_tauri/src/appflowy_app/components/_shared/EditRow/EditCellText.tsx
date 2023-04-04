import { CellController } from '$app/stores/effects/database/cell/cell_controller';
import { useEffect, useState, KeyboardEvent, useMemo } from 'react';

export const EditCellText = ({
  data,
  cellController,
}: {
  data: string | undefined;
  cellController: CellController<any, any>;
}) => {
  const [value, setValue] = useState('');
  const [contentRows, setContentRows] = useState(1);

  useEffect(() => {
    setValue(data || '');
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
    <div className={''}>
      <textarea
        className={'mt-0.5 h-full w-full resize-none px-4 py-2'}
        rows={contentRows}
        value={value}
        onChange={(e) => onTextFieldChange(e.target.value)}
        onBlur={() => save()}
      />
    </div>
  );
};
