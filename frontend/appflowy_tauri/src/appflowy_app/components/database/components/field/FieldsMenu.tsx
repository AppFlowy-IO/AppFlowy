import { Menu, MenuItem, MenuProps } from '@mui/material';
import { FC, MouseEvent } from 'react';
import { Field as FieldType } from '../../application';
import { useDatabaseVisibilityFields } from '../../Database.hooks';
import { Field } from './Field';

export interface FieldsMenuProps extends MenuProps {
  onMenuItemClick?: (event: MouseEvent<HTMLLIElement>, field: FieldType) => void;
}

export const FieldsMenu: FC<FieldsMenuProps> = ({ onMenuItemClick, ...props }) => {
  const fields = useDatabaseVisibilityFields();

  return (
    <Menu {...props}>
      {fields.map((field) => (
        <MenuItem
          key={field.id}
          value={field.id}
          onClick={(event) => {
            onMenuItemClick?.(event, field);
            props.onClose?.({}, 'backdropClick');
          }}
        >
          <Field field={field} />
        </MenuItem>
      ))}
    </Menu>
  );
};
