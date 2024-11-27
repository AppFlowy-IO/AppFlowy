import { useFiltersSelector, useSortsSelector } from '@/application/database-yjs';
import { useConditionsContext } from '@/components/database/components/conditions/context';
import { IconButton, Tooltip } from '@mui/material';
import React from 'react';
import { useTranslation } from 'react-i18next';
import { ReactComponent as FilterIcon } from '@/assets/filter.svg';
import { ReactComponent as SortIcon } from '@/assets/sort.svg';

export function DatabaseActions () {
  const { t } = useTranslation();

  const sorts = useSortsSelector();
  const filter = useFiltersSelector();
  const conditionsContext = useConditionsContext();

  return (
    <div className="flex w-[120px] items-center justify-end gap-1.5">
      <Tooltip title={t('grid.settings.filter')}>
        <IconButton
          onClick={() => {
            conditionsContext?.toggleExpanded();
          }}
          size={'small'}
          data-testid={'database-actions-filter'}
          color={filter.length > 0 ? 'primary' : undefined}
        >
          <FilterIcon />
        </IconButton>
      </Tooltip>
      <Tooltip title={t('grid.settings.sort')}>
        <IconButton
          size={'small'}
          data-testid={'database-actions-sort'}
          onClick={() => {
            conditionsContext?.toggleExpanded();
          }}
          color={sorts.length > 0 ? 'primary' : undefined}
        >
          <SortIcon />
        </IconButton>
      </Tooltip>
    </div>
  );
}

export default DatabaseActions;
