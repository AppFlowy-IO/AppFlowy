import React, { ChangeEventHandler, useCallback, useState } from 'react';
import { useViewId } from '$app/hooks';
import { fieldService } from '$app/components/database/application';
import { Log } from '$app/utils/log';
import TextField from '@mui/material/TextField';

function PropertyNameInput({ id, name }: { id: string; name: string }) {
  const viewId = useViewId();
  const [inputtingName, setInputtingName] = useState(name);

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

  return (
    <TextField
      className='mx-3 mt-3 rounded-[10px]'
      size='small'
      autoFocus={true}
      onKeyDown={(e) => {
        if (e.key === 'Enter') {
          e.preventDefault();
          e.stopPropagation();
          void handleSubmit();
        }
      }}
      value={inputtingName}
      onChange={handleInput}
      onBlur={handleSubmit}
    />
  );
}

export default PropertyNameInput;
