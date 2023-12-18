import React from 'react';
import {
  RunAllGridTests,
  TestCreateGrid,
  TestCreateNewField,
  TestCreateRow,
  TestCreateSelectOptionInCell,
  TestDeleteField,
  TestDeleteRow,
  TestEditCell,
  TestEditCheckboxCell,
  TestEditDateCell,
  TestEditDateFormat,
  TestEditField,
  TestEditNumberFormat,
  TestEditTextCell,
  TestEditURLCell,
  TestGetSingleSelectFieldData,
  TestMoveField,
  TestSwitchFromMultiSelectToText,
  TestSwitchFromSingleSelectToNumber,
} from './TestGrid';
import {
  TestCreateKanbanBoard,
  TestCreateKanbanBoardColumn,
  TestCreateKanbanBoardRowInNoStatusGroup,
  TestAllKanbanTests,
  TestMoveKanbanBoardColumn,
  TestMoveKanbanBoardRow,
} from './TestGroup';
import { TestCreateViews } from '$app/components/tests/TestFolder';

export const TestAPI = () => {
  return (
    <React.Fragment>
      <ul className='m-6, space-y-2'>
        {/*<tests></tests>*/}
        <RunAllGridTests></RunAllGridTests>
        <TestCreateGrid></TestCreateGrid>
        <TestCreateRow></TestCreateRow>
        <TestDeleteRow></TestDeleteRow>
        <TestEditCell></TestEditCell>
        <TestEditTextCell></TestEditTextCell>
        <TestEditURLCell></TestEditURLCell>
        <TestEditDateCell></TestEditDateCell>
        <TestEditCheckboxCell></TestEditCheckboxCell>
        <TestCreateSelectOptionInCell></TestCreateSelectOptionInCell>
        <TestGetSingleSelectFieldData></TestGetSingleSelectFieldData>
        <TestEditField></TestEditField>
        <TestMoveField></TestMoveField>
        <TestCreateNewField></TestCreateNewField>
        <TestDeleteField></TestDeleteField>
        <TestEditDateFormat></TestEditDateFormat>
        <TestEditNumberFormat></TestEditNumberFormat>
        <TestSwitchFromSingleSelectToNumber></TestSwitchFromSingleSelectToNumber>
        <TestSwitchFromMultiSelectToText></TestSwitchFromMultiSelectToText>
        {/*kanban board */}
        <TestAllKanbanTests></TestAllKanbanTests>
        <TestCreateKanbanBoard></TestCreateKanbanBoard>
        <TestCreateKanbanBoardRowInNoStatusGroup></TestCreateKanbanBoardRowInNoStatusGroup>
        <TestMoveKanbanBoardRow></TestMoveKanbanBoardRow>
        <TestMoveKanbanBoardColumn></TestMoveKanbanBoardColumn>
        <TestCreateKanbanBoardColumn></TestCreateKanbanBoardColumn>
        {/*Folders*/}
        <TestCreateViews></TestCreateViews>
      </ul>
    </React.Fragment>
  );
};
