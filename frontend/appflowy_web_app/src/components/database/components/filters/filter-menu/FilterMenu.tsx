import { YjsDatabaseKey } from '@/application/types';
import { FieldType, Filter, SelectOptionFilter, useFieldSelector } from '@/application/database-yjs';
import CheckboxFilterMenu from './CheckboxFilterMenu';
import ChecklistFilterMenu from './ChecklistFilterMenu';
import MultiSelectOptionFilterMenu from './MultiSelectOptionFilterMenu';
import NumberFilterMenu from './NumberFilterMenu';
import SingleSelectOptionFilterMenu from './SingleSelectOptionFilterMenu';
import TextFilterMenu from './TextFilterMenu';
import React, { useMemo } from 'react';

export function FilterMenu({ filter }: { filter: Filter }) {
  const { field } = useFieldSelector(filter?.fieldId);
  const fieldType = Number(field?.get(YjsDatabaseKey.type)) as FieldType;

  const menu = useMemo(() => {
    if (!field) return null;
    switch (fieldType) {
      case FieldType.RichText:
      case FieldType.URL:
        return <TextFilterMenu filter={filter} />;
      case FieldType.Checkbox:
        return <CheckboxFilterMenu filter={filter} />;
      case FieldType.Checklist:
        return <ChecklistFilterMenu filter={filter} />;
      case FieldType.Number:
        return <NumberFilterMenu filter={filter} />;
      case FieldType.MultiSelect:
        return <MultiSelectOptionFilterMenu filter={filter as SelectOptionFilter} />;
      case FieldType.SingleSelect:
        return <SingleSelectOptionFilterMenu filter={filter as SelectOptionFilter} />;
      default:
        return null;
    }
  }, [field, fieldType, filter]);

  return menu;
}

export default FilterMenu;
