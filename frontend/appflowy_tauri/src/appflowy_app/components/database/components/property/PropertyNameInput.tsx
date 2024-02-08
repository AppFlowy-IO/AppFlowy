import React, { ChangeEventHandler, useCallback, useEffect, useRef, useState } from 'react';
import { useViewId } from '$app/hooks';
import { fieldService } from '$app/application/database';
import { Log } from '$app/utils/log';
import TextField from '@mui/material/TextField';

const PropertyNameInput = React.forwardRef<HTMLInputElement, { id: string; name: string }>(({ id, name }, ref) => {
  const viewId = useViewId();
  const [inputtingName, setInputtingName] = useState(name);

  const inputRef = useRef<HTMLInputElement | null>(null);
  const handleInput = useCallback<ChangeEventHandler<HTMLInputElement>>((e) => {
    setInputtingName(e.target.value);
  }, []);

  const handleSubmit = useCallback(async () => {
    if (inputtingName !== name) {
      try {
        await fieldService.updateField(viewId, id, {
          name: inputtingName,
        });
      } catch (e) {
        // TODO
        Log.error(`change field ${id} name from '${name}' to ${inputtingName} fail`, e);
      }
    }
  }, [viewId, id, name, inputtingName]);

  useEffect(() => {
    const input = inputRef.current;

    if (!input) return;

    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Enter') {
        e.preventDefault();
        e.stopPropagation();
        void handleSubmit();
      }
    };

    input.addEventListener('keydown', handleKeyDown);
    return () => {
      input.removeEventListener('keydown', handleKeyDown);
    };
  }, [handleSubmit, ref]);

  return (
    <TextField
      className='mx-3 mt-3 rounded-[10px]'
      size='small'
      autoFocus={true}
      inputRef={(e) => {
        if (typeof ref === 'function') {
          ref(e);
        } else if (ref) {
          ref.current = e;
        }

        inputRef.current = e;
      }}
      value={inputtingName}
      onChange={handleInput}
      onBlur={handleSubmit}
    />
  );
});

export default PropertyNameInput;
