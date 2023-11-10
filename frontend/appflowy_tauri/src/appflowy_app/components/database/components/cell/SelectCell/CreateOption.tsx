import { MenuItem, MenuItemProps } from '@mui/material';
import { FC } from 'react';
import { Tag } from './Tag';

export interface CreateOptionProps {
  label: React.ReactNode;
  onClick?: MenuItemProps['onClick'];
}

export const CreateOption: FC<CreateOptionProps> = ({
  label,
  onClick,
}) => {
  return (
    <MenuItem
      className="mt-2"
      onClick={onClick}
    >
      <Tag className="ml-2" size="small" label={label} />
    </MenuItem>
  );
};