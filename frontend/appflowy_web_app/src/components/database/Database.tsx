import DatabaseViews from '@/components/database/DatabaseViews';

import React, { memo } from 'react';

export const Database = memo(
  ({
    viewId,
    onNavigateToView,
    iidIndex,
  }: {
    iidIndex: string;
    viewId: string;
    onNavigateToView: (viewId: string) => void;
  }) => {
    return (
      <div className='appflowy-database relative flex w-full flex-1 select-text flex-col overflow-y-hidden'>
        <DatabaseViews iidIndex={iidIndex} onChangeView={onNavigateToView} viewId={viewId} />
      </div>
    );
  }
);

export default Database;
