import React, { useMemo, useState } from 'react';
import { TextFilter as TextFilterType, TextFilterData } from '$app/application/database';
import { TextField } from '@mui/material';
import { useTranslation } from 'react-i18next';
import { TextFilterConditionPB } from '@/services/backend';
import debounce from 'lodash-es/debounce';

interface Props {
  filter: TextFilterType;
  onChange: (filterData: TextFilterData) => void;
}

const DELAY = 500;

function TextFilter({ filter, onChange }: Props) {
  const { t } = useTranslation();
  const [content, setContext] = useState(filter.data.content);
  const condition = filter.data.condition;
  const showField =
    condition !== TextFilterConditionPB.TextIsEmpty && condition !== TextFilterConditionPB.TextIsNotEmpty;

  const onConditionChange = useMemo(() => {
    return debounce((content: string) => {
      onChange({
        content,
        condition,
      });
    }, DELAY);
  }, [condition, onChange]);

  if (!showField) return null;
  return (
    <TextField
      spellCheck={false}
      className={'p-2 pt-0'}
      inputProps={{
        className: 'text-xs p-1.5',
      }}
      size={'small'}
      value={content}
      placeholder={t('grid.settings.typeAValue')}
      onChange={(e) => {
        setContext(e.target.value);
        onConditionChange(e.target.value ?? '');
      }}
    />
  );
}

export default TextFilter;
