import { useFiltersSelector, useReadOnly } from '@/application/database-yjs';
import Filter from '@/components/database/components/filters/Filter';
import Button from '@mui/material/Button';
import React from 'react';
import { useTranslation } from 'react-i18next';
import { ReactComponent as AddFilterSvg } from '$icons/16x/add.svg';

export function Filters() {
  const filters = useFiltersSelector();
  const { t } = useTranslation();
  const readOnly = useReadOnly();

  return (
    <>
      {filters.map((filterId) => (
        <Filter filterId={filterId} key={filterId} />
      ))}
      <Button
        disabled={readOnly}
        variant='text'
        color={'inherit'}
        className={'mx-1 whitespace-nowrap'}
        startIcon={<AddFilterSvg />}
        size='small'
      >
        {t('grid.settings.addFilter')}
      </Button>
    </>
  );
}

export default Filters;
