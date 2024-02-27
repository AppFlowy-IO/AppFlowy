import React, { ChangeEventHandler, useCallback, useMemo, useState } from 'react';
import { useViewId } from '$app/hooks';
import { fieldService } from '$app/application/database';
import { Log } from '$app/utils/log';
import TextField from '@mui/material/TextField';
import debounce from 'lodash-es/debounce';

const PropertyNameInput = React.forwardRef<HTMLInputElement, { id: string; name: string }>(({ id, name }, ref) => {
  const viewId = useViewId();
  const [inputtingName, setInputtingName] = useState(name);

  const handleSubmit = useCallback(
    async (newName: string) => {
      if (newName !== name) {
        try {
          await fieldService.updateField(viewId, id, {
            name: newName,
          });
        } catch (e) {
          // TODO
          Log.error(`change field ${id} name from '${name}' to ${newName} fail`, e);
        }
      }
    },
    [viewId, id, name]
  );

  const debouncedHandleSubmit = useMemo(() => debounce(handleSubmit, 500), [handleSubmit]);
  const handleInput = useCallback<ChangeEventHandler<HTMLInputElement>>(
    (e) => {
      setInputtingName(e.target.value);
      void debouncedHandleSubmit(e.target.value);
    },
    [debouncedHandleSubmit]
  );

  return (
    <TextField
      className='mx-3 mt-3 rounded-[10px]'
      size='small'
      inputRef={ref}
      autoFocus={true}
      value={inputtingName}
      onChange={handleInput}
    />
  );
});

export default PropertyNameInput;
