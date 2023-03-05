import { assertNumberOfRowsInGroup, createTestDatabaseView, openTestDatabase } from './DatabaseTestHelper';
import { ViewLayoutTypePB } from '../../../services/backend';
import React from 'react';

export const TestCreateKanbanBoard = () => {
  async function createBuildInBoard() {
    const view = await createTestDatabaseView(ViewLayoutTypePB.Board);
    const databaseController = await openTestDatabase(view.id);
    databaseController.subscribe({
      onGroupByField: (groups) => {
        console.log(groups);
        if (groups.length !== 4) {
          throw Error('The build-in board should have 4 groups');
        }
      },
    });
    await databaseController.open().then((result) => result.unwrap());
    await databaseController.dispose();
  }

  return TestButton('Test create build-in board', createBuildInBoard);
};

export const TestCreateKanbanBoardRowInNoStatusGroup = () => {
  async function createBuildInBoard() {
    const view = await createTestDatabaseView(ViewLayoutTypePB.Board);
    const databaseController = await openTestDatabase(view.id);
    await databaseController.open().then((result) => result.unwrap());

    // Create row in no status group
    const noStatusGroup = databaseController.groups.getValue()[0];
    await noStatusGroup.createRow().then((result) => result.unwrap());
    await assertNumberOfRowsInGroup(view.id, noStatusGroup.group.group_id, 1);

    await databaseController.dispose();
  }

  return TestButton('Test create row in build-in kanban board', createBuildInBoard);
};

export const TestButton = (title: string, onClick: () => void) => {
  return (
    <React.Fragment>
      <div>
        <button className='rounded-md bg-gray-300 p-4' type='button' onClick={() => onClick()}>
          {title}
        </button>
      </div>
    </React.Fragment>
  );
};
