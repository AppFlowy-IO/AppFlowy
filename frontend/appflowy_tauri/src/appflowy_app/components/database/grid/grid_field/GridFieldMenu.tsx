import React, { useRef } from 'react';
import Popover, { PopoverProps } from '@mui/material/Popover';
import { Field } from '$app/application/database';
import PropertyNameInput from '$app/components/database/components/property/PropertyNameInput';
import { MenuList } from '@mui/material';
import PropertyActions, { FieldAction } from '$app/components/database/components/property/PropertyActions';

interface Props extends PopoverProps {
  field: Field;
  onOpenPropertyMenu?: () => void;
  onOpenMenu?: (fieldId: string) => void;
}

export function GridFieldMenu({ field, onOpenPropertyMenu, onOpenMenu, onClose, ...props }: Props) {
  const inputRef = useRef<HTMLInputElement>(null);

  return (
    <Popover
      disableRestoreFocus={true}
      transformOrigin={{
        vertical: 'top',
        horizontal: 'left',
      }}
      onClick={(e) => e.stopPropagation()}
      {...props}
      onClose={onClose}
      keepMounted={false}
      onMouseDown={(e) => {
        const isInput = inputRef.current?.contains(e.target as Node);

        if (isInput) return;

        e.stopPropagation();
        e.preventDefault();
      }}
    >
      <PropertyNameInput ref={inputRef} id={field.id} name={field.name} />
      <MenuList>
        <PropertyActions
          inputRef={inputRef}
          isPrimary={field.isPrimary}
          onClose={() => onClose?.({}, 'backdropClick')}
          onMenuItemClick={(action, newFieldId?: string) => {
            if (action === FieldAction.EditProperty) {
              onOpenPropertyMenu?.();
            } else if (newFieldId && (action === FieldAction.InsertLeft || action === FieldAction.InsertRight)) {
              onOpenMenu?.(newFieldId);
            }

            onClose?.({}, 'backdropClick');
          }}
          fieldId={field.id}
        />
      </MenuList>
    </Popover>
  );
}

export default GridFieldMenu;
