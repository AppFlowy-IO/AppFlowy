import React from 'react';
import Popover, { PopoverProps } from '@mui/material/Popover';
import { Field } from '$app/components/database/application';
import PropertyNameInput from '$app/components/database/components/property/PropertyNameInput';
import { MenuList, Portal } from '@mui/material';
import PropertyActions, { FieldAction } from '$app/components/database/components/property/PropertyActions';

interface Props extends PopoverProps {
  field: Field;
  onOpenPropertyMenu?: () => void;
  onOpenMenu?: (fieldId: string) => void;
}

function GridFieldMenu({ field, onOpenPropertyMenu, onOpenMenu, ...props }: Props) {
  return (
    <Portal>
      <Popover
        transformOrigin={{
          vertical: 'top',
          horizontal: 'left',
        }}
        onClick={(e) => e.stopPropagation()}
        {...props}
        keepMounted={false}
      >
        <PropertyNameInput id={field.id} name={field.name} />
        <MenuList>
          <PropertyActions
            isPrimary={field.isPrimary}
            onMenuItemClick={(action, newFieldId?: string) => {
              if (action === FieldAction.EditProperty) {
                onOpenPropertyMenu?.();
              } else if (newFieldId && (action === FieldAction.InsertLeft || action === FieldAction.InsertRight)) {
                onOpenMenu?.(newFieldId);
              }

              props.onClose?.({}, 'backdropClick');
            }}
            fieldId={field.id}
          />
        </MenuList>
      </Popover>
    </Portal>
  );
}

export default GridFieldMenu;
