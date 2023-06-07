import React, { useEffect, useState } from 'react';
import ArrowLeftIcon from '@mui/icons-material/SubdirectoryArrowLeft';

function EditLink({
  text,
  value,
  onChange,
  onComplete,
}: {
  text: string;
  value: string;
  onChange?: (newValue: string) => void;
  onComplete?: (newValue: string) => void;
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
          className={'flex-1 outline-none'}
          onChange={(e) => {
            const newValue = e.target.value;
            setVal(newValue);
          }}
          onKeyDown={(e) => {
            if (e.key === 'Enter') {
              e.preventDefault();
              e.stopPropagation();
              onComplete?.(val);
            }
          }}
          value={val}
        />
        {onComplete && (
          <div className={'cursor-pointer text-shade-4'} onClick={() => onComplete?.(val)}>
            <ArrowLeftIcon
              sx={{
                fontSize: '1rem',
              }}
            />
          </div>
        )}
      </div>
    </div>
  );
}

export default EditLink;
