import { ChecklistFilter, ChecklistFilterCondition } from '@/application/database-yjs';
import FieldMenuTitle from '@/components/database/components/filters/filter-menu/FieldMenuTitle';
import React, { useMemo } from 'react';
import { useTranslation } from 'react-i18next';

function ChecklistFilterMenu({ filter }: { filter: ChecklistFilter }) {
  const { t } = useTranslation();

  const conditions = useMemo(
    () => [
      {
        value: ChecklistFilterCondition.IsComplete,
        text: t('grid.checklistFilter.isComplete'),
      },
      {
        value: ChecklistFilterCondition.IsIncomplete,
        text: t('grid.checklistFilter.isIncomplted'),
      },
    ],
    [t]
  );
  const selectedCondition = useMemo(() => {
    return conditions.find((c) => c.value === filter.condition);
  }, [filter.condition, conditions]);

  return (
    <div className={'p-2'}>
      <FieldMenuTitle fieldId={filter.fieldId} selectedConditionText={selectedCondition?.text ?? ''} />
    </div>
  );
}

export default ChecklistFilterMenu;
