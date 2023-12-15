import { Divider, MenuList } from '@mui/material';
import { FC, useCallback } from 'react';
import { useViewId } from '$app/hooks';
import { Field, fieldService } from '../../application';
import PropertyTypeMenuExtension from '$app/components/database/components/property/property_type/PropertyTypeMenuExtension';
import PropertyTypeSelect from '$app/components/database/components/property/property_type/PropertyTypeSelect';
import { FieldType } from '@/services/backend';
import { Log } from '$app/utils/log';
import Popover, { PopoverProps } from '@mui/material/Popover';
import PropertyNameInput from '$app/components/database/components/property/PropertyNameInput';
import PropertyActions, { FieldAction } from '$app/components/database/components/property/PropertyActions';

const actions = [FieldAction.Hide, FieldAction.Duplicate, FieldAction.Delete];

export interface GridFieldMenuProps extends PopoverProps {
  field: Field;
}

export const PropertyMenu: FC<GridFieldMenuProps> = ({ field, ...props }) => {
  const viewId = useViewId();

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
    <Popover
      transformOrigin={{
        vertical: -10,
        horizontal: 'left',
      }}
      anchorOrigin={{
        vertical: 'bottom',
        horizontal: 'left',
      }}
      onClick={(e) => e.stopPropagation()}
      keepMounted={false}
      {...props}
    >
      <PropertyNameInput id={field.id} name={field.name} />
      <MenuList>
        <div>
          {!isPrimary && (
            <>
              <PropertyTypeSelect field={field} onUpdateFieldType={onUpdateFieldType} />
              <Divider className={'my-2'} />
            </>
          )}
          <PropertyTypeMenuExtension field={field} />
          <PropertyActions
            isPrimary={isPrimary}
            actions={actions}
            onMenuItemClick={() => {
              props.onClose?.({}, 'backdropClick');
            }}
            fieldId={field.id}
          />
        </div>
      </MenuList>
    </Popover>
  );
};
