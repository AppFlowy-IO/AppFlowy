import React, { useCallback, useMemo, useRef, useState } from 'react';
import { OutlinedInput } from '@mui/material';
import { Property } from '$app/components/database/components/property/Property';
import { Field as FieldType } from '$app/application/database';
import { useDatabase } from '$app/components/database';
import KeyboardNavigation from '$app/components/_shared/keyboard_navigation/KeyboardNavigation';

interface FieldListProps {
  searchPlaceholder?: string;
  showSearch?: boolean;
  onItemClick?: (field: FieldType) => void;
  onClose?: () => void;
}

function PropertiesList({ onClose, showSearch, onItemClick, searchPlaceholder }: FieldListProps) {
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

  const inputRef = useRef<HTMLInputElement>(null);

  const searchInput = useMemo(() => {
    return showSearch ? (
      <div className={'w-[220px] px-4 pt-2'}>
        <OutlinedInput
          inputRef={inputRef}
          size={'small'}
          autoFocus={true}
          spellCheck={false}
          autoComplete={'off'}
          autoCorrect={'off'}
          inputProps={{
            className: 'text-xs p-1.5',
          }}
          placeholder={searchPlaceholder}
          onChange={onInputChange}
        />
      </div>
    ) : null;
  }, [onInputChange, searchPlaceholder, showSearch]);

  const scrollRef = useRef<HTMLDivElement>(null);

  const options = useMemo(() => {
    return fieldsResult.map((field) => {
      return {
        key: field.id,
        content: (
          <div className={'truncate'}>
            <Property field={field} />
          </div>
        ),
      };
    });
  }, [fieldsResult]);

  const onConfirm = useCallback(
    (key: string) => {
      const field = fields.find((field) => field.id === key);

      onItemClick?.(field as FieldType);
    },
    [fields, onItemClick]
  );

  return (
    <div className={'pt-2'}>
      {searchInput}
      <div ref={scrollRef} className={'my-2 max-h-[300px] overflow-y-auto overflow-x-hidden'}>
        <KeyboardNavigation
          disableFocus={true}
          scrollRef={scrollRef}
          focusRef={inputRef}
          options={options}
          onConfirm={onConfirm}
          onEscape={onClose}
        />
      </div>
    </div>
  );
}

export default PropertiesList;
