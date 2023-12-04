import React, { useCallback, useMemo, useState } from 'react';
import { OutlinedInput, MenuItem, MenuList } from '@mui/material';
import { Property } from '$app/components/database/components/property/Property';
import { Field as FieldType } from '../../application';
import { useDatabase } from '$app/components/database';

interface FieldListProps {
  searchPlaceholder?: string;
  showSearch?: boolean;
  onItemClick?: (event: React.MouseEvent<HTMLLIElement>, field: FieldType) => void;
}

function PropertiesList({ showSearch, onItemClick, searchPlaceholder }: FieldListProps) {
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
      <div className={'w-[220px] px-4 pt-2'}>
        <OutlinedInput size={'small'} autoFocus={true} placeholder={searchPlaceholder} onChange={onInputChange} />
      </div>
    ) : null;
  }, [onInputChange, searchPlaceholder, showSearch]);

  const emptyList = useMemo(() => {
    return fieldsResult.length === 0 ? (
      <div className={'px-4 pt-3 text-center text-sm font-medium text-gray-500'}>No fields found</div>
    ) : null;
  }, [fieldsResult]);

  return (
    <div className={'pt-2'}>
      {searchInput}
      {emptyList}
      <MenuList className={'max-h-[300px] overflow-y-auto overflow-x-hidden'}>
        {fieldsResult.map((field) => (
          <MenuItem
            className={'overflow-hidden text-ellipsis px-1'}
            key={field.id}
            value={field.id}
            onClick={(event) => {
              onItemClick?.(event, field);
            }}
          >
            <Property field={field} />
          </MenuItem>
        ))}
      </MenuList>
    </div>
  );
}

export default PropertiesList;
