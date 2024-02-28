import { Divider } from '@mui/material';
import { FC, useCallback, useMemo, useRef } from 'react';
import { useViewId } from '$app/hooks';
import { Field, fieldService } from '$app/application/database';
import PropertyTypeMenuExtension from '$app/components/database/components/property/property_type/PropertyTypeMenuExtension';
import PropertyTypeSelect from '$app/components/database/components/property/property_type/PropertyTypeSelect';
import { FieldType, FieldVisibility } from '@/services/backend';
import { Log } from '$app/utils/log';
import Popover, { PopoverProps } from '@mui/material/Popover';
import PropertyNameInput from '$app/components/database/components/property/PropertyNameInput';
import PropertyActions, { FieldAction } from '$app/components/database/components/property/PropertyActions';

export interface GridFieldMenuProps extends PopoverProps {
  field: Field;
}

export const PropertyMenu: FC<GridFieldMenuProps> = ({ field, ...props }) => {
  const viewId = useViewId();
  const inputRef = useRef<HTMLInputElement>(null);

  const isPrimary = field.isPrimary;
  const actions = useMemo(() => {
    const keys = [FieldAction.Duplicate, FieldAction.Delete];

    if (field.visibility === FieldVisibility.AlwaysHidden) {
      keys.unshift(FieldAction.Show);
    } else {
      keys.unshift(FieldAction.Hide);
    }

    return keys;
  }, [field.visibility]);

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
      keepMounted={false}
      onClick={(e) => e.stopPropagation()}
      onKeyDown={(e) => {
        if (e.key === 'Escape') {
          e.stopPropagation();
          e.preventDefault();
          props.onClose?.({}, 'escapeKeyDown');
        }
      }}
      onMouseDown={(e) => {
        const isInput = inputRef.current?.contains(e.target as Node);

        if (isInput) return;

        e.stopPropagation();
        e.preventDefault();
      }}
      {...props}
    >
      <PropertyNameInput ref={inputRef} id={field.id} name={field.name} />
      <div className={'flex-1 overflow-y-auto overflow-x-hidden py-1'}>
        {!isPrimary && (
          <div className={'pt-2'}>
            <PropertyTypeSelect field={field} onUpdateFieldType={onUpdateFieldType} />
            <Divider className={'my-2'} />
          </div>
        )}
        <PropertyTypeMenuExtension field={field} />
        <PropertyActions
          inputRef={inputRef}
          onClose={() => props.onClose?.({}, 'backdropClick')}
          isPrimary={isPrimary}
          actions={actions}
          onMenuItemClick={() => {
            props.onClose?.({}, 'backdropClick');
          }}
          fieldId={field.id}
        />
      </div>
    </Popover>
  );
};
