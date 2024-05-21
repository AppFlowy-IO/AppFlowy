import { useFiltersSelector, useSortsSelector } from '@/application/database-yjs';
import { useConditionsContext } from '@/components/database/components/conditions/context';
import { TextButton } from '@/components/database/components/tabs/TextButton';
import React from 'react';
import { useTranslation } from 'react-i18next';

export function DatabaseActions() {
  const { t } = useTranslation();
  const sorts = useSortsSelector();
  const filter = useFiltersSelector();
  const conditionsContext = useConditionsContext();

  return (
    <div className='flex w-[120px] items-center justify-end gap-1.5'>
      <TextButton
        onClick={() => {
          conditionsContext?.toggleExpanded();
        }}
        color={filter.length > 0 ? 'primary' : 'inherit'}
      >
        {t('grid.settings.filter')}
      </TextButton>
      <TextButton
        onClick={() => {
          conditionsContext?.toggleExpanded();
        }}
        color={sorts.length > 0 ? 'primary' : 'inherit'}
      >
        {t('grid.settings.sort')}
      </TextButton>
    </div>
  );
}

export default DatabaseActions;
