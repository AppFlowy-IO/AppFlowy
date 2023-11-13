import { MenuItem, Select, SelectChangeEvent, SelectProps } from '@mui/material';
import { FC, useCallback } from 'react';
import { Field as FieldType } from '../../application';
import { useDatabase } from '../../Database.hooks';
import { Field } from './Field';

export interface FieldSelectProps extends Omit<SelectProps, 'onChange'> {
  onChange?: (event: SelectChangeEvent<unknown>, field: FieldType | undefined) => void;
}

export const FieldSelect: FC<FieldSelectProps> = ({
  onChange,
  ...props
}) => {
  const { fields } = useDatabase();

  const handleChange = useCallback((event: SelectChangeEvent<unknown>) => {
    const selectedId = event.target.value;

    onChange?.(event, fields.find(field => field.id === selectedId));
  }, [onChange, fields]);

  return (
    <Select onChange={handleChange} {...props}>
      {fields.map(field => (
        <MenuItem key={field.id} value={field.id}>
          <Field field={field} />
        </MenuItem>
      ))}
    </Select>
  );
};
