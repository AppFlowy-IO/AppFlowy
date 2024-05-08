import { TextFilter, TextFilterCondition, useReadOnly } from '@/application/database-yjs';
import FieldMenuTitle from '@/components/database/components/filters/filter-menu/FieldMenuTitle';
import { TextField } from '@mui/material';
import React, { useMemo } from 'react';
import { useTranslation } from 'react-i18next';

function TextFilterMenu({ filter }: { filter: TextFilter }) {
  const { t } = useTranslation();
  const readOnly = useReadOnly();
  const conditions = useMemo(() => {
    return [
      {
        value: TextFilterCondition.TextContains,
        text: t('grid.textFilter.contains'),
      },
      {
        value: TextFilterCondition.TextDoesNotContain,
        text: t('grid.textFilter.doesNotContain'),
      },
      {
        value: TextFilterCondition.TextStartsWith,
        text: t('grid.textFilter.startWith'),
      },
      {
        value: TextFilterCondition.TextEndsWith,
        text: t('grid.textFilter.endsWith'),
      },
      {
        value: TextFilterCondition.TextIs,
        text: t('grid.textFilter.is'),
      },
      {
        value: TextFilterCondition.TextIsNot,
        text: t('grid.textFilter.isNot'),
      },
      {
        value: TextFilterCondition.TextIsEmpty,
        text: t('grid.textFilter.isEmpty'),
      },
      {
        value: TextFilterCondition.TextIsNotEmpty,
        text: t('grid.textFilter.isNotEmpty'),
      },
    ];
  }, [t]);

  const selectedCondition = useMemo(() => {
    return conditions.find((c) => c.value === filter.condition);
  }, [filter.condition, conditions]);

  const displayTextField = useMemo(() => {
    return ![TextFilterCondition.TextIsEmpty, TextFilterCondition.TextIsNotEmpty].includes(filter.condition);
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

export default TextFilterMenu;
