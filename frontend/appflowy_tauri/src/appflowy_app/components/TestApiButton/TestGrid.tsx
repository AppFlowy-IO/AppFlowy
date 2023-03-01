import React from 'react';
import { SelectOptionCellDataPB, ViewLayoutTypePB } from '../../../services/backend';
import { Log } from '../../utils/log';
import {
  assertFieldName,
  assertNumberOfFields,
  assertNumberOfRows,
  assertTextCell,
  createTestDatabaseView,
  editTextCell,
  makeSingleSelectCellController,
  openTestDatabase,
} from './DatabaseTestHelper';
import { SelectOptionBackendService } from '../../stores/effects/database/cell/select_option_bd_svc';
import { TypeOptionController } from '../../stores/effects/database/field/type_option/type_option_controller';
import { None, Some } from 'ts-results';
import { RowBackendService } from '../../stores/effects/database/row/row_bd_svc';

export const TestCreateGrid = () => {
  async function createBuildInGrid() {
    const view = await createTestDatabaseView(ViewLayoutTypePB.Grid);
    const databaseController = await openTestDatabase(view.id);
    databaseController.subscribe({
      onViewChanged: (databasePB) => {
        Log.debug('Did receive database:' + databasePB);
      },
      onRowsChanged: async (rows) => {
        if (rows.length !== 3) {
          throw Error('Expected number of rows is 3, but receive ' + rows.length);
        }
      },
      onFieldsChanged: (fields) => {
        if (fields.length !== 3) {
          throw Error('Expected number of fields is 3, but receive ' + fields.length);
        }
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
    await databaseController.open().then((result) => result.unwrap());

    for (const [index, row] of databaseController.databaseViewCache.rowInfos.entries()) {
      const cellContent = index.toString();
      await editTextCell(row, databaseController, cellContent);
      await assertTextCell(row, databaseController, cellContent);
    }
  }

  return TestButton('Test editing cell', testGridRow);
};

export const TestCreateRow = () => {
  async function testCreateRow() {
    const view = await createTestDatabaseView(ViewLayoutTypePB.Grid);
    const databaseController = await openTestDatabase(view.id);
    await databaseController.open().then((result) => result.unwrap());
    await assertNumberOfRows(view.id, 3);

    // Create a row from a DatabaseController or create using the RowBackendService
    await databaseController.createRow();
    await assertNumberOfRows(view.id, 4);
    await databaseController.dispose();
  }

  return TestButton('Test create row', testCreateRow);
};
export const TestDeleteRow = () => {
  async function testDeleteRow() {
    const view = await createTestDatabaseView(ViewLayoutTypePB.Grid);
    const databaseController = await openTestDatabase(view.id);
    await databaseController.open().then((result) => result.unwrap());

    const rows = databaseController.databaseViewCache.rowInfos;
    const svc = new RowBackendService(view.id);
    await svc.deleteRow(rows[0].row.id);
    await assertNumberOfRows(view.id, 2);

    // Wait the databaseViewCache get the change notification and
    // update the rows.
    await new Promise((resolve) => setTimeout(resolve, 200));
    if (databaseController.databaseViewCache.rowInfos.length !== 2) {
      throw Error('The number of rows is not match');
    }
    await databaseController.dispose();
  }

  return TestButton('Test delete row', testDeleteRow);
};
export const TestCreateSelectOption = () => {
  async function testCreateOption() {
    const view = await createTestDatabaseView(ViewLayoutTypePB.Grid);
    const databaseController = await openTestDatabase(view.id);
    await databaseController.open().then((result) => result.unwrap());
    for (const [index, row] of databaseController.databaseViewCache.rowInfos.entries()) {
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
        await cellController.dispose();
      }
    }
    await databaseController.dispose();
  }

  return TestButton('Test create a select option', testCreateOption);
};

export const TestEditField = () => {
  async function testEditField() {
    const view = await createTestDatabaseView(ViewLayoutTypePB.Grid);
    const databaseController = await openTestDatabase(view.id);
    await databaseController.open().then((result) => result.unwrap());
    const fieldInfos = databaseController.fieldController.fieldInfos;

    // Modify the name of the field
    const firstFieldInfo = fieldInfos[0];
    const controller = new TypeOptionController(view.id, Some(firstFieldInfo));
    await controller.initialize();
    const newName = 'hello world';
    await controller.setFieldName(newName);

    await assertFieldName(view.id, firstFieldInfo.field.id, firstFieldInfo.field.field_type, newName);
    await databaseController.dispose();
  }

  return TestButton('Test edit the column name', testEditField);
};

export const TestCreateNewField = () => {
  async function testCreateNewField() {
    const view = await createTestDatabaseView(ViewLayoutTypePB.Grid);
    const databaseController = await openTestDatabase(view.id);
    await databaseController.open().then((result) => result.unwrap());
    await assertNumberOfFields(view.id, 3);

    // Modify the name of the field
    const controller = new TypeOptionController(view.id, None);
    await controller.initialize();
    await assertNumberOfFields(view.id, 4);
    await databaseController.dispose();
  }

  return TestButton('Test create a new column', testCreateNewField);
};

export const TestDeleteField = () => {
  async function testDeleteField() {
    const view = await createTestDatabaseView(ViewLayoutTypePB.Grid);
    const databaseController = await openTestDatabase(view.id);
    await databaseController.open().then((result) => result.unwrap());

    // Modify the name of the field.
    // The fieldInfos[0] is the primary field by default, we can't delete it.
    // So let choose the second fieldInfo.
    const fieldInfo = databaseController.fieldController.fieldInfos[1];
    const controller = new TypeOptionController(view.id, Some(fieldInfo));
    await controller.initialize();
    await assertNumberOfFields(view.id, 3);
    await controller.deleteField();
    await assertNumberOfFields(view.id, 2);
    await databaseController.dispose();
  }

  return TestButton('Test delete a new column', testDeleteField);
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
