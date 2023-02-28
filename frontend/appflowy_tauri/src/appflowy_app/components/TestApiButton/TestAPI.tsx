import React from 'react';
import TestApiButton from './TestApiButton';
import { TestCreateGridButton } from './TestCreateGrid';

export const TestAPI = () => {
  return (
    <React.Fragment>
      <ul className='m-6, space-y-2'>
        <TestApiButton></TestApiButton>
        <TestCreateGridButton></TestCreateGridButton>
      </ul>
    </React.Fragment>
  );
};
