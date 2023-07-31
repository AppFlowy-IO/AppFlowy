import React, { useEffect, useState } from 'react';
import TextField from '@mui/material/TextField';

function EditLink({
  autoFocus,
  text,
  value,
  onChange,
}: {
  autoFocus?: boolean;
  text: string;
  value: string;
  onChange?: (newValue: string) => void;
}) {
  const [val, setVal] = useState(value);

  useEffect(() => {
    onChange?.(val);
  }, [val, onChange]);

  return (
    <div className={'mb-2 w-[100%] text-sm'}>
      <TextField
        className={'w-[100%]'}
        label={text}
        autoFocus={autoFocus}
        variant='standard'
        onChange={(e) => {
          const newValue = e.target.value;

          setVal(newValue);
        }}
        value={val}
      />
    </div>
  );
}

export default EditLink;
