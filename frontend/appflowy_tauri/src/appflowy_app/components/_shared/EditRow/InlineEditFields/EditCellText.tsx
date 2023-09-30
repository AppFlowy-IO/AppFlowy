import { useEffect, useState } from 'react';

export const EditCellText = ({ data, onSave }: { data: string | undefined; onSave: (value: string) => void }) => {
  const [value, setValue] = useState('');
  const [contentRows, setContentRows] = useState(1);

  useEffect(() => {
    setValue(data ?? '');
  }, [data]);

  useEffect(() => {
    if (!value?.length) return;
    setContentRows(Math.max(1, (value ?? '').split('\n').length));
  }, [value]);

  const onTextFieldChange = async (v: string) => {
    setValue(v);
  };

  return (
    <div>
      <textarea
        className={'mt-0.5 h-full w-full resize-none px-4 py-1'}
        rows={contentRows}
        value={value}
        onChange={(e) => onTextFieldChange(e.target.value)}
        onBlur={() => onSave(value)}
      />
    </div>
  );
};
