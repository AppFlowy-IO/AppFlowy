import { useSortsSelector } from '@/application/database-yjs';
import Sort from '@/components/database/components/sorts/Sort';
import React from 'react';

function SortList() {
  const sorts = useSortsSelector();

  return (
    <div className={'flex w-fit flex-col gap-2 p-2'}>
      {sorts.map((sortId) => (
        <Sort sortId={sortId} key={sortId} />
      ))}
    </div>
  );
}

export default SortList;
