import React, { useState } from 'react';
import { Field, TextFilter as TextFilterType, TextFilterData } from '$app/components/database/application';
import TextFilterConditionSelect from '$app/components/database/components/filter/field_filter/TextFilterConditionSelect';
import { TextField } from '@mui/material';
import { useTranslation } from 'react-i18next';

interface Props {
  filter: TextFilterType;
  field: Field;
  onChange: (filterData: TextFilterData) => void;
}
function TextFilter({ filter, field, onChange }: Props) {
  const { t } = useTranslation();
  const [selectedCondition, setSelectedCondition] = useState(filter.data.condition);
  const [content, setContext] = useState(filter.data.content);

  return (
    <div className={'flex flex-col'}>
      <div className={'mb-3 flex gap-[20px]'}>
        <div className={'text-text-caption'}>{field.name}</div>
        <TextFilterConditionSelect
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

export default TextFilter;
