import { FieldDisplay } from '@/components/database/components/field';
import React from 'react';

function PropertyWrapper({ fieldId, children }: { fieldId: string; children: React.ReactNode }) {
  return (
    <div className={'flex min-h-[28px] w-full gap-2'}>
      <div className={'property-label flex h-[28px] w-[30%] items-center'}>
        <FieldDisplay fieldId={fieldId} />
      </div>
      <div className={'flex flex-1 flex-wrap overflow-x-hidden pr-1'}>{children}</div>
    </div>
  );
}

export default PropertyWrapper;
