import React, { useState } from 'react';
import { Field, TextFilter as TextFilterType, TextFilterData } from '$app/components/database/application';
import TextFilterConditionSelect from '$app/components/database/components/filter/text_filter/TextFilterConditionSelect';
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
      <div className={'flex justify-between gap-[20px] p-2 pb-0 pr-10'}>
        <div className={'flex-1 text-sm text-text-caption'}>{field.name}</div>
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

export default TextFilter;
