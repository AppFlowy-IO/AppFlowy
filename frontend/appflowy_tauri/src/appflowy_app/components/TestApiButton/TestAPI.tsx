import React from 'react';
import TestApiButton from './TestApiButton';
import {
  TestCreateGrid,
  TestCreateNewField,
  TestCreateSelectOption,
  TestDeleteField,
  TestEditCell,
  TestEditField,
} from './TestGrid';

export const TestAPI = () => {
  return (
    <React.Fragment>
      <ul className='m-6, space-y-2'>
        <TestApiButton></TestApiButton>
        <TestCreateGrid></TestCreateGrid>
        <TestEditCell></TestEditCell>
        <TestCreateSelectOption></TestCreateSelectOption>
        <TestEditField></TestEditField>
        <TestCreateNewField></TestCreateNewField>
        {/*<TestDeleteField></TestDeleteField>*/}
      </ul>
    </React.Fragment>
  );
};
