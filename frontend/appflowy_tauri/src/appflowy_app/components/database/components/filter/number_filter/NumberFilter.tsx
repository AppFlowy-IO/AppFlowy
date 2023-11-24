import React, { useState } from 'react';
import { Field, NumberFilter as NumberFilterType, NumberFilterData } from '$app/components/database/application';
import { useTranslation } from 'react-i18next';
import { TextField } from '@mui/material';
import NumberFilterConditionSelect from '$app/components/database/components/filter/number_filter/NumberFilterConditionSelect';

interface Props {
  filter: NumberFilterType;
  field: Field;
  onChange: (filterData: NumberFilterData) => void;
}

function NumberFilter({ filter, field, onChange }: Props) {
  const { t } = useTranslation();
  const [selectedCondition, setSelectedCondition] = useState(filter.data.condition);
  const [content, setContext] = useState(filter.data.content);

  return (
    <div className={'flex flex-col'}>
      <div className={'flex justify-between gap-[20px] p-2 pb-0 pr-10'}>
        <div className={'flex-1 text-sm text-text-caption'}>{field.name}</div>
        <NumberFilterConditionSelect
          onChange={(e) => {
            const value = Number(e.target.value);

            setSelectedCondition(value);
            onChange({
              condition: value,
              content,
            });
          }}
          value={selectedCondition}
        />
      </div>
      <TextField
        className={'p-2'}
        size={'small'}
        value={content}
        placeholder={t('grid.settings.typeAValue')}
        onChange={(e) => {
          setContext(e.target.value);
        }}
        onBlur={() => {
          onChange({
            condition: selectedCondition,
            content,
          });
        }}
      />
    </div>
  );
}

export default NumberFilter;
