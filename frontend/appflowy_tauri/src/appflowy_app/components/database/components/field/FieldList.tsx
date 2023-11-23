import React, { useCallback, useMemo, useState } from 'react';
import { Input, MenuItem } from '@mui/material';
import { Field } from '$app/components/database/components/field/Field';
import { Field as FieldType } from '../../application';
import { useDatabase } from '$app/components/database';

interface FieldListProps {
  searchPlaceholder?: string;
  showSearch?: boolean;
  onItemClick?: (event: React.MouseEvent<HTMLLIElement>, field: FieldType) => void;
}

function FieldList({ showSearch, onItemClick, searchPlaceholder }: FieldListProps) {
  const { fields } = useDatabase();
  const [fieldsResult, setFieldsResult] = useState<FieldType[]>(fields as FieldType[]);

  const onInputChange = useCallback(
    (event: React.ChangeEvent<HTMLInputElement>) => {
      const value = event.target.value;
      const result = fields.filter((field) => field.name.toLowerCase().includes(value.toLowerCase()));

      setFieldsResult(result);
    },
    [fields]
  );

  const searchInput = useMemo(() => {
    return showSearch ? (
      <div className={'w-full px-8 py-2'}>
        <Input placeholder={searchPlaceholder} onChange={onInputChange} />
      </div>
    ) : null;
  }, [onInputChange, searchPlaceholder, showSearch]);

  const emptyList = useMemo(() => {
    return fieldsResult.length === 0 ? (
      <div className={'px-8 py-4 text-center text-gray-500'}>No fields found</div>
    ) : null;
  }, [fieldsResult]);

  return (
    <>
      {searchInput}
      {emptyList}
      {fieldsResult.map((field) => (
        <MenuItem
          key={field.id}
          value={field.id}
          onClick={(event) => {
            onItemClick?.(event, field);
          }}
        >
          <Field field={field} />
        </MenuItem>
      ))}
    </>
  );
}

export default FieldList;
