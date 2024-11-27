import { DatabaseContext, useDatabaseView, useFiltersSelector, useSortsSelector } from '@/application/database-yjs';
import { DatabaseViewLayout, YjsDatabaseKey } from '@/application/types';
import { AFScroller } from '@/components/_shared/scroller';
import { useConditionsContext } from '@/components/database/components/conditions/context';
import React, { useContext, useMemo } from 'react';
import Filters from 'src/components/database/components/filters/Filters';
import Sorts from 'src/components/database/components/sorts/Sorts';

export function DatabaseConditions () {
  const conditionsContext = useConditionsContext();
  const expanded = conditionsContext?.expanded ?? false;
  const sorts = useSortsSelector();
  const filters = useFiltersSelector();
  const view = useDatabaseView();
  const scrollLeft = useContext(DatabaseContext)?.scrollLeft;
  const layout = Number(view?.get(YjsDatabaseKey.layout));
  const className = useMemo(() => {
    const classList = ['database-conditions min-w-0 max-w-full relative transform overflow-hidden transition-all'];

    if (layout === DatabaseViewLayout.Grid) {
      classList.push('max-sm:!pl-6');
      classList.push('pl-24');
    } else {
      classList.push('max-sm:!px-6');
      classList.push('px-24');
    }

    return classList.join(' ');
  }, [layout]);

  return (
    <div
      style={{
        height: expanded ? '40px' : '0',
        paddingInline: scrollLeft === undefined ? '96px' : `${scrollLeft}px`,
        paddingRight: layout === DatabaseViewLayout.Grid ? '0' : undefined,
      }}
      className={
        className
      }
    >
      <AFScroller
        overflowYHidden
        className={`flex border-t border-line-divider ${layout === DatabaseViewLayout.Grid ? 'max-sm:pr-6 pr-24' : ''} items-center gap-2`}
      >
        <Sorts />
        {sorts.length > 0 && filters.length > 0 && <div className="h-[20px] w-0 border border-line-divider" />}
        <Filters />
      </AFScroller>
    </div>
  );
}

export default DatabaseConditions;
