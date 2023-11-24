import React from 'react';
import { useDatabase } from '$app/components/database';
import { Field as FieldType } from '$app/components/database/application';
import { Field } from '$app/components/database/components/field';
import { FieldVisibility } from '@/services/backend';
import { ReactComponent as EyeOpen } from '$app/assets/eye_open.svg';
import { ReactComponent as EyeClosed } from '$app/assets/eye_close.svg';
import { MenuItem } from '@mui/material';

interface PropertiesProps {
  onItemClick: (field: FieldType) => void;
}
function Properties({ onItemClick }: PropertiesProps) {
  const { fields } = useDatabase();

  return (
    <div className={'max-h-[300px] overflow-y-auto py-2'}>
      {fields.map((field) => (
        <MenuItem
          disabled={field.isPrimary}
          onClick={() => onItemClick(field)}
          className={'flex w-full items-center justify-between'}
          key={field.id}
        >
          <Field field={field} />
          <div className={'ml-2'}>{field.visibility !== FieldVisibility.AlwaysHidden ? <EyeOpen /> : <EyeClosed />}</div>
        </MenuItem>
      ))}
    </div>
  );
}

export default Properties;
