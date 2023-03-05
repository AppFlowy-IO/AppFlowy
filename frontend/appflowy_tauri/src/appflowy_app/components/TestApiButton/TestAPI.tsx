import React from 'react';
import {
  TestCreateGrid,
  TestCreateNewField,
  TestCreateRow,
  TestCreateSelectOptionInCell,
  TestDeleteField,
  TestDeleteRow,
  TestEditCell,
  TestEditField,
  TestGetSingleSelectFieldData,
  TestSwitchFromMultiSelectToText,
  TestSwitchFromSingleSelectToNumber,
} from './TestGrid';
import {
  TestCreateKanbanBoard,
  TestCreateKanbanBoardColumn,
  TestCreateKanbanBoardRowInNoStatusGroup,
  TestKanbanAllTests,
  TestMoveKanbanBoardColumn,
  TestMoveKanbanBoardRow,
} from './TestGroup';

export const TestAPI = () => {
  return (
    <React.Fragment>
      <ul className='m-6, space-y-2'>
        {/*<TestApiButton></TestApiButton>*/}
        <TestCreateGrid></TestCreateGrid>
        <TestCreateRow></TestCreateRow>
        <TestDeleteRow></TestDeleteRow>
        <TestEditCell></TestEditCell>
        <TestCreateSelectOptionInCell></TestCreateSelectOptionInCell>
        <TestGetSingleSelectFieldData></TestGetSingleSelectFieldData>
        <TestEditField></TestEditField>
        <TestCreateNewField></TestCreateNewField>
        <TestDeleteField></TestDeleteField>
        <TestSwitchFromSingleSelectToNumber></TestSwitchFromSingleSelectToNumber>
        <TestSwitchFromMultiSelectToText></TestSwitchFromMultiSelectToText>
        {/*kanban board */}
        <TestKanbanAllTests></TestKanbanAllTests>
        <TestCreateKanbanBoard></TestCreateKanbanBoard>
        <TestCreateKanbanBoardRowInNoStatusGroup></TestCreateKanbanBoardRowInNoStatusGroup>
        <TestMoveKanbanBoardRow></TestMoveKanbanBoardRow>
        <TestMoveKanbanBoardColumn></TestMoveKanbanBoardColumn>
        <TestCreateKanbanBoardColumn></TestCreateKanbanBoardColumn>
      </ul>
    </React.Fragment>
  );
};
