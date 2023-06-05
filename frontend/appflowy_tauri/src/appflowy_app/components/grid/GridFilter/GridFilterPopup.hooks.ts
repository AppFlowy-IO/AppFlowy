import { useAppSelector } from '@/appflowy_app/stores/store';
import { useEffect, useState } from 'react';

export const useGridFilterPopup = () => {
  const database = useAppSelector((state) => state.database);

  const [filters, setFilters] = useState<any>([]);

  const fields = Object.values(database.fields).map((field) => {
    return {
      fieldId: field.fieldId,
      name: field.title,
      fieldType: field.fieldType,
    };
  });
  useEffect(() => {
    setFilters([
      {
        fieldId: 'f:kIZGIK',
        operator: 'contains',
        value: 'test',
      },
    ]);
  }, []);

  const addFilter = () => {
    setFilters([
      ...filters,
      {
        field: 'name',
        operator: 'contains',
        value: 'test' + filters.length,
      },
    ]);
  };

  const onFieldChange = (index: number, fieldId: string) => {
    const newFilters = [...filters];
    newFilters[index].fieldId = fieldId;
    setFilters(newFilters);
  };

  return {
    fields,
    filters,
    addFilter,
    onFieldChange,
  };
};
