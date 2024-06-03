import ComponentLoading from '@/components/_shared/progress/ComponentLoading';
import { DatabaseRowProperties, DatabaseRowSubDocument } from '@/components/database/components/database-row';
import DatabaseRowHeader from '@/components/database/components/header/DatabaseRowHeader';
import { Divider } from '@mui/material';
import React, { Suspense } from 'react';

export function DatabaseRow({ rowId }: { rowId: string }) {
  return (
    <div className={'flex w-full justify-center'}>
      <div className={'max-w-screen w-[964px] min-w-0'}>
        <div className={' relative flex  flex-col gap-4'}>
          <DatabaseRowHeader rowId={rowId} />

          <div className={'flex flex-1 flex-col gap-4'}>
            <Suspense>
              <DatabaseRowProperties rowId={rowId} />
            </Suspense>
            <Divider className={'mx-16 max-md:mx-4'} />
            <Suspense fallback={<ComponentLoading />}>
              <DatabaseRowSubDocument rowId={rowId} />
            </Suspense>
          </div>
        </div>
      </div>
    </div>
  );
}

export default DatabaseRow;
