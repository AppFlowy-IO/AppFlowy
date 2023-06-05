import { useAppSelector } from '@/appflowy_app/stores/store';
import { useEffect, useState } from 'react';

export const useGridSortPopup = () => {
  const database = useAppSelector((state) => state.database);
  const fields = Object.values(database.fields).map((field) => {
    return {
      fieldId: field.fieldId,
      name: field.title,
      fieldType: field.fieldType,
    };
  });

  const [sortRules, setsortRules] = useState<any>([]);

  useEffect(() => {
    setsortRules([
      {
        fieldId: 'f:kIZGIK',
        direction: 'asc',
      },
    ]);
  }, []);

  const onSortRuleFieldChange = (index: number, fieldId: string) => {
    const newSortRules = [...sortRules];
    newSortRules[index].fieldId = fieldId;
    setsortRules(newSortRules);
  };

  const addSortRule = () => {
    setsortRules([
      ...sortRules,
      {
        fieldId: 'f:kIZGIK',
        direction: 'asc',
      },
    ]);
  };

  return {
    fields,
    sortRules,
    onSortRuleFieldChange,
    addSortRule,
  };
};
