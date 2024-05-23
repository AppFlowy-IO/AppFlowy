import { FieldDisplay } from '@/components/database/components/field';
import React from 'react';

function PropertyWrapper({ fieldId, children }: { fieldId: string; children: React.ReactNode }) {
  return (
    <div className={'flex w-full items-center gap-2'}>
      <div className={'w-[100px] text-text-caption'}>
        <FieldDisplay fieldId={fieldId} />
      </div>
      <div className={'flex flex-1 flex-wrap pr-1'}>{children}</div>
    </div>
  );
}

export default PropertyWrapper;
