import {
  assert,
  assertNumberOfRowsInGroup,
  createSingleSelectOptions,
  createTestDatabaseView,
  openTestDatabase,
} from './DatabaseTestHelper';
import { FieldType, ViewLayoutPB } from '../../../services/backend';
import React from 'react';

export const TestAllKanbanTests = () => {
  async function run() {
    await createBuildInBoard();
    await createKanbanBoardRow();
    await moveKanbanBoardRow();
    await createKanbanBoardColumn();
    await createColumnInBoard();
  }

  return (
    <React.Fragment>
      <div>
        <button className='rounded-md bg-red-400 p-4' type='button' onClick={() => run()}>
          Run all kanban board tests
        </button>
      </div>
    </React.Fragment>
  );
};

async function createBuildInBoard() {
  const view = await createTestDatabaseView(ViewLayoutPB.Board);
  const databaseController = await openTestDatabase(view.id);
  databaseController.subscribe({
    onGroupByField: (groups) => {
      console.log(groups);
      if (groups.length !== 4) {
        throw Error('The build-in board should have 4 groups');
      }

      assert(groups[0].rows.length === 0, 'The no status group should have 0 rows');
      assert(groups[1].rows.length === 3, 'The first group should have 3 rows');
      assert(groups[2].rows.length === 0, 'The second group should have 0 rows');
      assert(groups[3].rows.length === 0, 'The third group should have 0 rows');
    },
  });
  await databaseController.open().then((result) => result.unwrap());
  await databaseController.dispose();
}

async function createKanbanBoardRow() {
  const view = await createTestDatabaseView(ViewLayoutPB.Board);
  const databaseController = await openTestDatabase(view.id);
  await databaseController.open().then((result) => result.unwrap());

  // Create row in no status group
  const noStatusGroup = databaseController.groups.getValue()[0];
  await noStatusGroup.createRow().then((result) => result.unwrap());
  await assertNumberOfRowsInGroup(view.id, noStatusGroup.groupId, 1);

  await databaseController.dispose();
}

async function moveKanbanBoardRow() {
  const view = await createTestDatabaseView(ViewLayoutPB.Board);
  const databaseController = await openTestDatabase(view.id);
  await databaseController.open().then((result) => result.unwrap());

  // Create row in no status group
  const firstGroup = databaseController.groups.getValue()[1];
  const secondGroup = databaseController.groups.getValue()[2];
  // subscribe the group changes
  firstGroup.subscribe({
    onRemoveRow: (groupId, deleteRowId) => {
      console.log(groupId + 'did remove:' + deleteRowId);
    },
    onInsertRow: (groupId, rowPB) => {
      console.log(groupId + 'did insert:' + rowPB.id);
    },
    onUpdateRow: (groupId, rowPB) => {
      console.log(groupId + 'did update:' + rowPB.id);
    },
    onCreateRow: (groupId, rowPB) => {
      console.log(groupId + 'did create:' + rowPB.id);
    },
  });

  secondGroup.subscribe({
    onRemoveRow: (groupId, deleteRowId) => {
      console.log(groupId + 'did remove:' + deleteRowId);
    },
    onInsertRow: (groupId, rowPB) => {
      console.log(groupId + 'did insert:' + rowPB.id);
    },
    onUpdateRow: (groupId, rowPB) => {
      console.log(groupId + 'did update:' + rowPB.id);
    },
    onCreateRow: (groupId, rowPB) => {
      console.log(groupId + 'did create:' + rowPB.id);
    },
  });

  const row = firstGroup.rowAtIndex(0).unwrap();
  await databaseController.moveGroupRow(row.id, secondGroup.groupId);

  assert(firstGroup.rows.length === 2);
  await assertNumberOfRowsInGroup(view.id, firstGroup.groupId, 2);

  assert(secondGroup.rows.length === 1);
  await assertNumberOfRowsInGroup(view.id, secondGroup.groupId, 1);

  await databaseController.dispose();
}

async function createKanbanBoardColumn() {
  const view = await createTestDatabaseView(ViewLayoutPB.Board);
  const databaseController = await openTestDatabase(view.id);
  await databaseController.open().then((result) => result.unwrap());

  // Create row in no status group
  const firstGroup = databaseController.groups.getValue()[1];
  const secondGroup = databaseController.groups.getValue()[2];
  await databaseController.moveGroup(firstGroup.groupId, secondGroup.groupId);

  assert(databaseController.groups.getValue()[1].groupId === secondGroup.groupId);
  assert(databaseController.groups.getValue()[2].groupId === firstGroup.groupId);
  await databaseController.dispose();
}

async function createColumnInBoard() {
  const view = await createTestDatabaseView(ViewLayoutPB.Board);
  const databaseController = await openTestDatabase(view.id);
  await databaseController.open().then((result) => result.unwrap());

  // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
  const singleSelect = databaseController.fieldController.fieldInfos.find(
    (fieldInfo) => fieldInfo.field.field_type === FieldType.SingleSelect
  )!;

  // Create a option which will cause creating a new group
  const name = 'New column';
  await createSingleSelectOptions(view.id, singleSelect, [name]);

  // Wait the backend posting the notification to update the groups
  await new Promise((resolve) => setTimeout(resolve, 200));
  assert(databaseController.groups.value.length === 5, 'expect number of groups is 5');
  assert(databaseController.groups.value[4].name === name, 'expect the last group name is ' + name);
  await databaseController.dispose();
}

export const TestCreateKanbanBoard = () => {
  return TestButton('Test create build-in board', createBuildInBoard);
};

export const TestCreateKanbanBoardRowInNoStatusGroup = () => {
  return TestButton('Test create row in build-in kanban board', createKanbanBoardRow);
};

export const TestMoveKanbanBoardRow = () => {
  return TestButton('Test move row in build-in kanban board', moveKanbanBoardRow);
};

export const TestMoveKanbanBoardColumn = () => {
  return TestButton('Test move column in build-in kanban board', createKanbanBoardColumn);
};

export const TestCreateKanbanBoardColumn = () => {
  return TestButton('Test create column in build-in kanban board', createColumnInBoard);
};

export const TestButton = (title: string, onClick: () => void) => {
  return (
    <React.Fragment>
      <div>
        <button className='rounded-md bg-yellow-200 p-4' type='button' onClick={() => onClick()}>
          {title}
        </button>
      </div>
    </React.Fragment>
  );
};
