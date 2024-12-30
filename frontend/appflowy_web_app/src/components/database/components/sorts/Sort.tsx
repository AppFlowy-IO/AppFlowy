import { useSortSelector } from '@/application/database-yjs';
import SortCondition from '@/components/database/components/sorts/SortCondition';
import React from 'react';
import { FieldDisplay } from 'src/components/database/components/field';

function Sort({ sortId }: { sortId: string }) {
  const sort = useSortSelector(sortId);

  if (!sort) return null;
  return (
    <div data-testid={'sort-condition'} className={'flex items-center gap-1.5'}>
      <div className={'w-[120px] max-w-[250px] overflow-hidden  rounded-full border border-line-divider py-1 px-2 '}>
        <FieldDisplay fieldId={sort.fieldId} />
      </div>
      <SortCondition sort={sort} />
    </div>
  );
}

export default Sort;
