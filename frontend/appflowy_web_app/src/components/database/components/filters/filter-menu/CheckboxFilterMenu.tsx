import { CheckboxFilter, CheckboxFilterCondition } from '@/application/database-yjs';
import FieldMenuTitle from '@/components/database/components/filters/filter-menu/FieldMenuTitle';
import React, { useMemo } from 'react';
import { useTranslation } from 'react-i18next';

function CheckboxFilterMenu({ filter }: { filter: CheckboxFilter }) {
  const { t } = useTranslation();

  const conditions = useMemo(
    () => [
      {
        value: CheckboxFilterCondition.IsChecked,
        text: t('grid.checkboxFilter.isChecked'),
      },
      {
        value: CheckboxFilterCondition.IsUnChecked,
        text: t('grid.checkboxFilter.isUnchecked'),
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

export default CheckboxFilterMenu;
