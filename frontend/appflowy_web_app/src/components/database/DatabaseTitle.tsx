import { usePageInfo } from '@/components/_shared/page/usePageInfo';
import React from 'react';

function DatabaseTitle({ viewId }: { viewId: string }) {
  const { name, icon } = usePageInfo(viewId);

  return (
    <div className={'flex w-full flex-col py-4'}>
      <div className={'flex w-full items-center px-24 max-md:px-4'}>
        <div className={'flex items-center gap-2 text-3xl'}>
          <div>{icon}</div>
          <div className={'font-bold'}>{name}</div>
        </div>
      </div>
    </div>
  );
}

export default DatabaseTitle;
