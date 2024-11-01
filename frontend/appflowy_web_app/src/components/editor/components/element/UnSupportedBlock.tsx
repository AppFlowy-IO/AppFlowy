import { EditorElementProps } from '@/components/editor/editor.type';
import React, { forwardRef } from 'react';
import { Alert } from '@mui/material';

export const UnSupportedBlock = forwardRef<HTMLDivElement, EditorElementProps>(({ node }, ref) => {
  return (
    <div
      className={'w-full'}
      ref={ref}
    >
      <Alert
        className={'h-fit w-full'}
        severity={'warning'}
      >
        <div className={'text-base font-semibold'}>{`Unsupported Block: ${node.type}`}</div>

        <div className={'whitespace-pre my-4 font-medium'}>
          {`We're sorry for inconvenience \n`}
          Submit an issue on our{' '}<a
          className={'underline text-fill-default'}
          href={'https://github.com/AppFlowy-IO/AppFlowy/issues/new?template=bug_report.yaml'}
        >Github</a>{' '}page that describes your error
        </div>

        <span className={'text-sm'}>
          <pre><code>{JSON.stringify(node, null, 2)}</code></pre>
        </span>

      </Alert>
    </div>
  );
});
