import React from 'react';
import { SelectOptionCellDataPB, ViewLayoutTypePB } from '../../../services/backend';
import { Log } from '../../utils/log';
import {
  assertTextCell,
  createTestDatabaseView,
  editTextCell,
  makeSingleSelectCellController,
  openTestDatabase,
} from './DatabaseTestHelper';
import assert from 'assert';
import { SelectOptionBackendService } from '../../stores/effects/database/cell/select_option_bd_svc';

export const TestCreateGrid = () => {
  async function createBuildInGrid() {
    const view = await createTestDatabaseView(ViewLayoutTypePB.Grid);
    const databaseController = await openTestDatabase(view.id);
    databaseController.subscribe({
      onViewChanged: (databasePB) => {
        Log.debug('Did receive database:' + databasePB);
      },
      onRowsChanged: async (rows) => {
        assert(rows.length === 3);
      },
      onFieldsChanged: (fields) => {
        assert(fields.length === 3);
      },
    });
    await databaseController.open().then((result) => result.unwrap());
  }

  return TestButton('Test create build-in grid', createBuildInGrid);
};

export const TestEditCell = () => {
  async function testGridRow() {
    const view = await createTestDatabaseView(ViewLayoutTypePB.Grid);
    const databaseController = await openTestDatabase(view.id);
    databaseController.subscribe({
      onRowsChanged: async (rows) => {
        for (const [index, row] of rows.entries()) {
          const cellContent = index.toString();
          await editTextCell(row, databaseController, cellContent);
          await assertTextCell(row, databaseController, cellContent);
        }
      },
    });
    await databaseController.open().then((result) => result.unwrap());
  }

  return TestButton('Test editing cell', testGridRow);
};

export const TestCreateSelectOption = () => {
  async function testCreateOption() {
    const view = await createTestDatabaseView(ViewLayoutTypePB.Grid);
    const databaseController = await openTestDatabase(view.id);
    databaseController.subscribe({
      onRowsChanged: async (rows) => {
        for (const [index, row] of rows.entries()) {
          if (index === 0) {
            const cellController = await makeSingleSelectCellController(row, databaseController).then((result) =>
              result.unwrap()
            );
            cellController.subscribeChanged({
              onCellChanged: (value) => {
                const option: SelectOptionCellDataPB = value.unwrap();
                console.log(option);
              },
            });
            const backendSvc = new SelectOptionBackendService(cellController.cellIdentifier);
            await backendSvc.createOption({ name: 'option' + index });
          }
        }
      },
    });
    await databaseController.open().then((result) => result.unwrap());
  }

  return TestButton('Test create a select option', testCreateOption);
};

const TestButton = (title: string, onClick: () => void) => {
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
