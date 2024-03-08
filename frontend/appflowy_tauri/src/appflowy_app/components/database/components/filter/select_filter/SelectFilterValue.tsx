import React, { useMemo } from 'react';
import { SelectFilterData, SelectTypeOption } from '$app/application/database';
import { useStaticTypeOption } from '$app/components/database';
import { useTranslation } from 'react-i18next';
import { SelectOptionConditionPB } from '@/services/backend';

function SelectFilterValue({ data, fieldId }: { data: SelectFilterData; fieldId: string }) {
  const typeOption = useStaticTypeOption<SelectTypeOption>(fieldId);
  const { t } = useTranslation();
  const value = useMemo(() => {
    if (!data.optionIds?.length) return '';

    const options = data.optionIds
      .map((optionId) => {
        const option = typeOption?.options?.find((option) => option.id === optionId);

        return option?.name;
      })
      .join(', ');

    switch (data.condition) {
      case SelectOptionConditionPB.OptionIs:
        return `: ${options}`;
      case SelectOptionConditionPB.OptionIsNot:
        return `: ${t('grid.textFilter.choicechipPrefix.isNot')} ${options}`;
      case SelectOptionConditionPB.OptionIsEmpty:
        return `: ${t('grid.textFilter.choicechipPrefix.isEmpty')}`;
      case SelectOptionConditionPB.OptionIsNotEmpty:
        return `: ${t('grid.textFilter.choicechipPrefix.isNotEmpty')}`;
      default:
        return '';
    }
  }, [data.condition, data.optionIds, t, typeOption?.options]);

  return <>{value}</>;
}

export default SelectFilterValue;
