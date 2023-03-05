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
  TestEditField,
  TestGetSingleSelectFieldData,
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
import { TestCreateDocument } from './TestDocument';

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
        <TestCreateSelectOptionInCell></TestCreateSelectOptionInCell>
        <TestGetSingleSelectFieldData></TestGetSingleSelectFieldData>
        <TestEditField></TestEditField>
        <TestCreateNewField></TestCreateNewField>
        <TestDeleteField></TestDeleteField>
        <TestSwitchFromSingleSelectToNumber></TestSwitchFromSingleSelectToNumber>
        <TestSwitchFromMultiSelectToText></TestSwitchFromMultiSelectToText>
        {/*kanban board */}
        <TestAllKanbanTests></TestAllKanbanTests>
        <TestCreateKanbanBoard></TestCreateKanbanBoard>
        <TestCreateKanbanBoardRowInNoStatusGroup></TestCreateKanbanBoardRowInNoStatusGroup>
        <TestMoveKanbanBoardRow></TestMoveKanbanBoardRow>
        <TestMoveKanbanBoardColumn></TestMoveKanbanBoardColumn>
        <TestCreateKanbanBoardColumn></TestCreateKanbanBoardColumn>
        <TestCreateDocument></TestCreateDocument>
      </ul>
    </React.Fragment>
  );
};
