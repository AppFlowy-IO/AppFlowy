import emptyImageSrc from '@/assets/images/empty.png';
import { Alert } from '@mui/material';
import React from 'react';
import { ReactComponent as WarningIcon } from '@/assets/close_error.svg';

function SomethingError ({ error }: { error: Error }) {
  return (
    <div className={'flex h-full w-full flex-col items-center justify-center'}>
      <div
        className={'text-2xl font-bold text-text-title opacity-70 flex items-center gap-4'}
      >
        <WarningIcon className={'w-12 h-12'} />
        SomethingError
      </div>
      <Alert className={'max-w-[90%] px-6 whitespace-pre-wrap break-words '} severity={'error'}>{error.message}</Alert>
      <div className={'text-lg text-center text-text-title opacity-50 mt-4 whitespace-pre'}>
        {`We're sorry for inconvenience\n`}
        Submit an issue on our{' '}<a
        className={'underline text-fill-default'}
        href={'https://github.com/AppFlowy-IO/AppFlowy/issues/new?template=bug_report.yaml'}
      >Github</a>{' '}page that describes your error
      </div>
      <img src={emptyImageSrc} alt={'AppFlowy'} />
    </div>
  );
}

export default SomethingError;