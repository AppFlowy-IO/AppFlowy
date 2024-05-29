import { NumberFilter, NumberFilterCondition, useReadOnly } from '@/application/database-yjs';
import FieldMenuTitle from '@/components/database/components/filters/filter-menu/FieldMenuTitle';
import { TextField } from '@mui/material';
import React, { useMemo } from 'react';
import { useTranslation } from 'react-i18next';

function NumberFilterMenu({ filter }: { filter: NumberFilter }) {
  const { t } = useTranslation();
  const readOnly = useReadOnly();
  const conditions = useMemo(() => {
    return [
      {
        value: NumberFilterCondition.Equal,
        text: t('grid.numberFilter.equal'),
      },
      {
        value: NumberFilterCondition.NotEqual,
        text: t('grid.numberFilter.notEqual'),
      },
      {
        value: NumberFilterCondition.GreaterThan,
        text: t('grid.numberFilter.greaterThan'),
      },
      {
        value: NumberFilterCondition.LessThan,
        text: t('grid.numberFilter.lessThan'),
      },
      {
        value: NumberFilterCondition.GreaterThanOrEqualTo,
        text: t('grid.numberFilter.greaterThanOrEqualTo'),
      },
      {
        value: NumberFilterCondition.LessThanOrEqualTo,
        text: t('grid.numberFilter.lessThanOrEqualTo'),
      },
      {
        value: NumberFilterCondition.NumberIsEmpty,
        text: t('grid.textFilter.isEmpty'),
      },
      {
        value: NumberFilterCondition.NumberIsNotEmpty,
        text: t('grid.textFilter.isNotEmpty'),
      },
    ];
  }, [t]);

  const selectedCondition = useMemo(() => {
    return conditions.find((c) => c.value === filter.condition);
  }, [filter.condition, conditions]);

  const displayTextField = useMemo(() => {
    return ![NumberFilterCondition.NumberIsEmpty, NumberFilterCondition.NumberIsNotEmpty].includes(filter.condition);
  }, [filter.condition]);

  return (
    <div className={'flex flex-col gap-2 p-2'}>
      <FieldMenuTitle fieldId={filter.fieldId} selectedConditionText={selectedCondition?.text ?? ''} />
      {displayTextField && (
        <TextField
          disabled={readOnly}
          spellCheck={false}
          inputProps={{
            className: 'text-xs p-1.5',
          }}
          size={'small'}
          value={filter.content}
          placeholder={t('grid.settings.typeAValue')}
        />
      )}
    </div>
  );
}

export default NumberFilterMenu;
