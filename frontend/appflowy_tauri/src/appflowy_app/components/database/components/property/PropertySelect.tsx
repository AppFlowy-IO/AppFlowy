import { MenuItem, Select, SelectChangeEvent, SelectProps } from '@mui/material';
import { FC, useCallback } from 'react';
import { Field as FieldType } from '../../application';
import { useDatabase } from '../../Database.hooks';
import { Property } from './Property';

export interface FieldSelectProps extends Omit<SelectProps, 'onChange'> {
  onChange?: (field: FieldType | undefined) => void;
}

export const PropertySelect: FC<FieldSelectProps> = ({ onChange, ...props }) => {
  const { fields } = useDatabase();

  const handleChange = useCallback(
    (event: SelectChangeEvent<unknown>) => {
      const selectedId = event.target.value;

      onChange?.(fields.find((field) => field.id === selectedId));
    },
    [onChange, fields]
  );

  return (
    <Select
      onChange={handleChange}
      {...props}
      sx={{
        '& .MuiInputBase-input': {
          display: 'flex',
          alignItems: 'center',
        },
      }}
      MenuProps={{
        className: 'max-w-[150px]',
      }}
    >
      {fields.map((field) => (
        <MenuItem className={'overflow-hidden text-ellipsis px-1.5'} key={field.id} value={field.id}>
          <Property field={field} />
        </MenuItem>
      ))}
    </Select>
  );
};
