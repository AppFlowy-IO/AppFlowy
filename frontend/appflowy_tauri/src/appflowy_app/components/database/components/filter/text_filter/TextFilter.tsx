import React, { useState } from 'react';
import { TextFilter as TextFilterType, TextFilterData } from '$app/components/database/application';
import { TextField } from '@mui/material';
import { useTranslation } from 'react-i18next';
import { TextFilterConditionPB } from '@/services/backend';

interface Props {
  filter: TextFilterType;
  onChange: (filterData: TextFilterData) => void;
}
function TextFilter({ filter, onChange }: Props) {
  const { t } = useTranslation();
  const [content, setContext] = useState(filter.data.content);
  const condition = filter.data.condition;
  const showField =
    condition !== TextFilterConditionPB.TextIsEmpty && condition !== TextFilterConditionPB.TextIsNotEmpty;

  if (!showField) return null;
  return (
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
          content,
          condition,
        });
      }}
    />
  );
}

export default TextFilter;
