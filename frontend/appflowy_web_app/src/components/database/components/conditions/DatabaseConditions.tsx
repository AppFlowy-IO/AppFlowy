import { useFiltersSelector, useSortsSelector } from '@/application/database-yjs';
import { AFScroller } from '@/components/_shared/scroller';
import { useConditionsContext } from '@/components/database/components/conditions/context';
import React from 'react';
import Filters from 'src/components/database/components/filters/Filters';
import Sorts from 'src/components/database/components/sorts/Sorts';

export function DatabaseConditions () {
  const conditionsContext = useConditionsContext();
  const expanded = conditionsContext?.expanded ?? false;
  const sorts = useSortsSelector();
  const filters = useFiltersSelector();

  return (
    <div
      style={{
        height: expanded ? '40px' : '0',
        borderTopWidth: expanded ? '1px' : '0',
      }}
      className={
        'database-conditions relative transform overflow-hidden border-t border-line-divider transition-all'
      }
    >
      <AFScroller overflowYHidden className={'flex items-center gap-2'}>
        <Sorts />
        {sorts.length > 0 && filters.length > 0 && <div className="h-[20px] w-0 border border-line-divider" />}
        <Filters />
      </AFScroller>
    </div>
  );
}

export default DatabaseConditions;
