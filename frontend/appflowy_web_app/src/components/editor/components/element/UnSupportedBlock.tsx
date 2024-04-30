import { EditorElementProps } from '@/components/editor/editor.type';
import React, { forwardRef } from 'react';
import { Alert } from '@mui/material';

export const UnSupportedBlock = forwardRef<HTMLDivElement, EditorElementProps>(({ node }, ref) => {
  return (
    <div className={'w-full'} ref={ref}>
      <Alert className={'h-[48px] w-full'} severity={'error'}>
        {`Unsupported block: ${node.type}`}
      </Alert>
    </div>
  );
});
