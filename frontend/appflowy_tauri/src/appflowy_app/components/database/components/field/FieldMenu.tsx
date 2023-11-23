import { Divider, Menu, MenuProps, OutlinedInput } from '@mui/material';
import { ChangeEventHandler, FC, useCallback, useState } from 'react';
import { useViewId } from '$app/hooks';
import { Field, fieldService } from '../../application';
import { FieldMenuActions } from './FieldMenuActions';
import FieldTypeMenuExtension from '$app/components/database/components/field/FieldTypeMenuExtension';
import FieldTypeSelect from '$app/components/database/components/field/FieldTypeSelect';
import { FieldType } from '@/services/backend';
import { Log } from '$app/utils/log';

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
        Log.error(`change field ${field.id} name from '${field.name}' to ${inputtingName} fail`, e);
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

  const isPrimary = field.isPrimary;

  const onUpdateFieldType = useCallback(
    async (type: FieldType) => {
      try {
        await fieldService.updateFieldType(viewId, field.id, type);
      } catch (e) {
        // TODO
        Log.error(`change field ${field.id} type from '${field.type}' to ${type} fail`, e);
      }
    },
    [viewId, field]
  );

  return (
    <Menu keepMounted={false} anchorEl={anchorEl} open={open} onClose={onClose}>
      <div>
        {fieldNameInput}
        {!isPrimary && (
          <>
            <FieldTypeSelect field={field} onUpdateFieldType={onUpdateFieldType} />
            <Divider />
          </>
        )}
        <FieldTypeMenuExtension field={field} />
        <FieldMenuActions isPrimary={isPrimary} onMenuItemClick={() => onClose()} fieldId={field.id} />
      </div>
    </Menu>
  );
};
