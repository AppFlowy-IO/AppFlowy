import { FieldDisplay } from '@/components/database/components/field';
import React from 'react';

function PropertyWrapper({ fieldId, children }: { fieldId: string; children: React.ReactNode }) {
  return (
    <div className={'flex min-h-[28px] w-full gap-2'}>
      <div className={'property-label flex h-auto w-[30%] items-center py-2'}>
        <FieldDisplay fieldId={fieldId} />
      </div>
      <div className={'flex h-fit flex-1 flex-wrap items-center overflow-x-hidden py-2 pr-1'}>{children}</div>
    </div>
  );
}

export default PropertyWrapper;
