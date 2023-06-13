import React, { useEffect, useState } from 'react';

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
    <div className={'mb-2 text-sm'}>
      <div className={'mb-1 text-shade-2'}>{text}</div>
      <div className={'flex rounded border bg-main-selector p-1 focus-within:border-main-hovered'}>
        <input
          autoFocus={autoFocus}
          className={'flex-1 outline-none'}
          onChange={(e) => {
            const newValue = e.target.value;
            setVal(newValue);
          }}
          value={val}
        />
      </div>
    </div>
  );
}

export default EditLink;
