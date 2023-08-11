import { Database } from '$app/interfaces/database';
import { Divider, Grid , IconButton, Menu, MenuItem, OutlinedInput } from '@mui/material';
import { ChangeEventHandler, FC, useCallback, useRef, useState } from 'react';
import { ReactComponent as DetailsSvg } from '$app/assets/details.svg';
import { ReactComponent as HideSvg } from '$app/assets/hide.svg';
import { ReactComponent as CopySvg } from '$app/assets/copy.svg';
import { ReactComponent as DeleteSvg } from '$app/assets/delete.svg';
import { ReactComponent as LeftSvg } from '$app/assets/left.svg';
import { ReactComponent as RightSvg } from '$app/assets/right.svg';
import { ReactComponent as MoreSvg } from '$app/assets/more.svg';
import { database } from '$app/stores/database';
import * as service from '$app/stores/database/bd_svc';
import { FieldTypeSvg } from './FieldTypeSvg';

const ActionSvgMap = {
  'hide': HideSvg,
  'duplicate': CopySvg,
  'delete': DeleteSvg,
  'insert-left': LeftSvg,
  'insert-right': RightSvg,
}

const TwoColumnActions = [
  ['hide', 'duplicate', 'delete'] as const,
  ['insert-left', 'insert-right'] as const,
];

export const GridField: FC<{
  field: Database.Field;
}> = ({ field }) => {
  const anchorEl = useRef<HTMLDivElement>(null);
  const [open, setOpen] = useState(false);
  const [inputtingName, setInputtingName] = useState(field.name);

  const handleClick = useCallback(() => {
    setOpen(true);
  }, [])

  const handleClose = useCallback(() => {
    setOpen(false);
  }, []);

  const handleInput = useCallback<ChangeEventHandler<HTMLInputElement>>((e) => {
    setInputtingName(e.target.value);
  }, []);

  const handleBlur = useCallback(async () => {
    if (inputtingName !== field.name) {
      try {
        await service.updateField(database.viewId, field.id, {
          name: inputtingName,
        });
      } catch (e) {
        // TODO
        console.error(`change field ${field.id} name from '${field.name}' to ${inputtingName} fail`, e);
      }
    }
  }, [field, inputtingName]);

  return (
    <div
      ref={anchorEl}
      className="flex items-center p-3 h-full"
    >
      <div className="flex flex-1 items-center">
        <FieldTypeSvg type={field.type} className="text-base mr-2" />
        <span className="text-xs font-medium">
          {field.name}
        </span>
      </div>
      <IconButton size="small" onClick={handleClick}>
        <DetailsSvg />
      </IconButton>
      <Menu
        anchorEl={anchorEl.current}
        open={open}
        onClose={handleClose}
      >
        <OutlinedInput
          className="mx-3 mt-1 mb-5 !rounded-[10px]"
          size="small"
          value={inputtingName}
          onChange={handleInput}
          onBlur={handleBlur}
        />
        <MenuItem dense>
          <FieldTypeSvg type={field.type} className="text-base mr-2" />
          <span className="flex-1 text-xs font-medium">
            {field.type}
          </span>
          <MoreSvg className="text-base" />
        </MenuItem>
        <Divider />
        <Grid container spacing={2}>
          {TwoColumnActions.map((column, index) => (
            <Grid key={index} item xs={6}>
              {column.map(action => {
                const ActionSvg = ActionSvgMap[action];

                return (
                  <MenuItem key={action} dense>
                    <ActionSvg className="mr-2 text-base" />
                    {action}
                  </MenuItem>
                )
              })}
            </Grid>
          ))}
        </Grid>
      </Menu>
    </div>
  );
}