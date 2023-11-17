import { Divider, Menu, MenuItem, MenuProps, OutlinedInput } from '@mui/material';
import { ChangeEventHandler, FC, useCallback, useState } from 'react';
import { ReactComponent as MoreSvg } from '$app/assets/more.svg';
import { useViewId } from '$app/hooks';
import { Field, fieldService } from '../../application';
import { FieldMenuActions } from './FieldMenuActions';
import { FieldTypeText, FieldTypeSvg } from '$app/components/database/components/field/index';

export interface GridFieldMenuProps {
  field: Field;
  anchorEl: MenuProps['anchorEl'];
  open: boolean;
  onClose: () => void;
}

export const FieldMenu: FC<GridFieldMenuProps> = ({ field, anchorEl, open, onClose }) => {
  const viewId = useViewId();
  const [inputtingName, setInputtingName] = useState(field.name);

  const handleInput = useCallback<ChangeEventHandler<HTMLInputElement>>((e) => {
    setInputtingName(e.target.value);
  }, []);

  const handleBlur = useCallback(async () => {
    if (inputtingName !== field.name) {
      try {
        await fieldService.updateField(viewId, field.id, {
          name: inputtingName,
        });
      } catch (e) {
        // TODO
        console.error(`change field ${field.id} name from '${field.name}' to ${inputtingName} fail`, e);
      }
    }
  }, [viewId, field, inputtingName]);

  const fieldNameInput = (
    <OutlinedInput
      className='mx-3 mb-5 mt-1 !rounded-[10px]'
      size='small'
      value={inputtingName}
      onChange={handleInput}
      onBlur={handleBlur}
    />
  );

  const fieldTypeSelect = (
    <MenuItem dense>
      <FieldTypeSvg type={field.type} className='mr-2 text-base' />
      <span className='flex-1 text-xs font-medium'>
        <FieldTypeText type={field.type} />
      </span>
      <MoreSvg className='text-base' />
    </MenuItem>
  );

  const isPrimary = field.isPrimary;

  return (
    <Menu keepMounted={false} anchorEl={anchorEl} open={open} onClose={onClose}>
      {fieldNameInput}
      {!isPrimary && (
        <div>
          {fieldTypeSelect}
          <Divider />
        </div>
      )}

      <FieldMenuActions isPrimary={isPrimary} onMenuItemClick={() => onClose()} fieldId={field.id} />
    </Menu>
  );
};
