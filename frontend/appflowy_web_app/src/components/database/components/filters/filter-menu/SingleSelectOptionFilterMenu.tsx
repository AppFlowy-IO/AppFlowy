import { SelectOptionFilter, SelectOptionFilterCondition } from '@/application/database-yjs';
import { SelectOptionList } from '@/components/database/components/field/select-option';
import FieldMenuTitle from '@/components/database/components/filters/filter-menu/FieldMenuTitle';
import React, { useMemo } from 'react';
import { useTranslation } from 'react-i18next';

function SingleSelectOptionFilterMenu({ filter }: { filter: SelectOptionFilter }) {
  const { t } = useTranslation();
  const conditions = useMemo(() => {
    return [
      {
        value: SelectOptionFilterCondition.OptionIs,
        text: t('grid.selectOptionFilter.is'),
      },
      {
        value: SelectOptionFilterCondition.OptionIsNot,
        text: t('grid.selectOptionFilter.isNot'),
      },
      {
        value: SelectOptionFilterCondition.OptionIsEmpty,
        text: t('grid.selectOptionFilter.isEmpty'),
      },
      {
        value: SelectOptionFilterCondition.OptionIsNotEmpty,
        text: t('grid.selectOptionFilter.isNotEmpty'),
      },
    ];
  }, [t]);

  const selectedCondition = useMemo(() => {
    return conditions.find((c) => c.value === filter.condition);
  }, [filter.condition, conditions]);

  const displaySelectOptionList = useMemo(() => {
    return ![SelectOptionFilterCondition.OptionIsEmpty, SelectOptionFilterCondition.OptionIsNotEmpty].includes(
      filter.condition
    );
  }, [filter.condition]);

  return (
    <div className={'flex flex-col gap-2 p-2'}>
      <FieldMenuTitle fieldId={filter.fieldId} selectedConditionText={selectedCondition?.text ?? ''} />
      {displaySelectOptionList && <SelectOptionList fieldId={filter.fieldId} selectedIds={filter.optionIds} />}
    </div>
  );
}

export default SingleSelectOptionFilterMenu;
