import { FieldType, ViewLayoutTypePB, ViewPB, WorkspaceSettingPB } from '../../../services/backend';
import { FolderEventReadCurrentWorkspace } from '../../../services/backend/events/flowy-folder';
import { AppBackendService } from '../../stores/effects/folder/app/app_bd_svc';
import { DatabaseController } from '../../stores/effects/database/database_controller';
import { RowInfo } from '../../stores/effects/database/row/row_cache';
import { RowController } from '../../stores/effects/database/row/row_controller';
import {
  CellControllerBuilder,
  DateCellController,
  NumberCellController,
  SelectOptionCellController,
  TextCellController,
} from '../../stores/effects/database/cell/controller_builder';
import { None, Option, Some } from 'ts-results';
import { TypeOptionBackendService } from '../../stores/effects/database/field/type_option/type_option_bd_svc';
import { DatabaseBackendService } from '../../stores/effects/database/database_bd_svc';

// Create a database view for specific layout type
// Do not use it production code. Just for testing
export async function createTestDatabaseView(layout: ViewLayoutTypePB): Promise<ViewPB> {
  const workspaceSetting: WorkspaceSettingPB = await FolderEventReadCurrentWorkspace().then((result) => result.unwrap());
  const app = workspaceSetting.workspace.apps.items[0];
  const appService = new AppBackendService(app.id);
  return await appService.createView({ name: 'New Grid', layoutType: layout });
}

export async function openTestDatabase(viewId: string): Promise<DatabaseController> {
  return new DatabaseController(viewId);
}

export async function assertTextCell(
  fieldId: string,
  rowInfo: RowInfo,
  databaseController: DatabaseController,
  expectedContent: string
) {
  const cellController = await makeTextCellController(fieldId, rowInfo, databaseController).then((result) =>
    result.unwrap()
  );
  cellController.subscribeChanged({
    onCellChanged: (value) => {
      const cellContent = value.unwrap();
      if (cellContent !== expectedContent) {
        throw Error('Text cell content is not match');
      }
    },
  });
  await cellController.getCellData();
}

export async function editTextCell(
  fieldId: string,
  rowInfo: RowInfo,
  databaseController: DatabaseController,
  content: string
) {
  const cellController = await makeTextCellController(fieldId, rowInfo, databaseController).then((result) =>
    result.unwrap()
  );
  await cellController.saveCellData(content);
}

export async function makeTextCellController(
  fieldId: string,
  rowInfo: RowInfo,
  databaseController: DatabaseController
): Promise<Option<TextCellController>> {
  const builder = await makeCellControllerBuilder(fieldId, rowInfo, FieldType.RichText, databaseController).then(
    (result) => result.unwrap()
  );
  return Some(builder.build() as TextCellController);
}

export async function makeNumberCellController(
  fieldId: string,
  rowInfo: RowInfo,
  databaseController: DatabaseController
): Promise<Option<NumberCellController>> {
  const builder = await makeCellControllerBuilder(fieldId, rowInfo, FieldType.Number, databaseController).then(
    (result) => result.unwrap()
  );
  return Some(builder.build() as NumberCellController);
}

export async function makeSingleSelectCellController(
  fieldId: string,
  rowInfo: RowInfo,
  databaseController: DatabaseController
): Promise<Option<SelectOptionCellController>> {
  const builder = await makeCellControllerBuilder(fieldId, rowInfo, FieldType.SingleSelect, databaseController).then(
    (result) => result.unwrap()
  );
  return Some(builder.build() as SelectOptionCellController);
}

export async function makeMultiSelectCellController(
  fieldId: string,
  rowInfo: RowInfo,
  databaseController: DatabaseController
): Promise<Option<SelectOptionCellController>> {
  const builder = await makeCellControllerBuilder(fieldId, rowInfo, FieldType.MultiSelect, databaseController).then(
    (result) => result.unwrap()
  );
  return Some(builder.build() as SelectOptionCellController);
}

export async function makeDateCellController(
  fieldId: string,
  rowInfo: RowInfo,
  databaseController: DatabaseController
): Promise<Option<DateCellController>> {
  const builder = await makeCellControllerBuilder(fieldId, rowInfo, FieldType.DateTime, databaseController).then(
    (result) => result.unwrap()
  );
  return Some(builder.build() as DateCellController);
}

export async function makeCellControllerBuilder(
  fieldId: string,
  rowInfo: RowInfo,
  fieldType: FieldType,
  databaseController: DatabaseController
): Promise<Option<CellControllerBuilder>> {
  const rowCache = databaseController.databaseViewCache.getRowCache();
  const cellCache = rowCache.getCellCache();
  const fieldController = databaseController.fieldController;
  const rowController = new RowController(rowInfo, fieldController, rowCache);
  const cellByFieldId = await rowController.loadCells();
  for (const cellIdentifier of cellByFieldId.values()) {
    const builder = new CellControllerBuilder(cellIdentifier, cellCache, fieldController);
    if (cellIdentifier.fieldId === fieldId) {
      return Some(builder);
    }
  }

  return None;
}

export function findFirstFieldInfoWithFieldType(rowInfo: RowInfo, fieldType: FieldType) {
  const fieldInfo = rowInfo.fieldInfos.find((element) => element.field.field_type === fieldType);
  if (fieldInfo === undefined) {
    return None;
  } else {
    return Some(fieldInfo);
  }
}

export async function assertFieldName(viewId: string, fieldId: string, fieldType: FieldType, expected: string) {
  const svc = new TypeOptionBackendService(viewId);
  const typeOptionPB = await svc.getTypeOption(fieldId, fieldType).then((result) => result.unwrap());
  if (typeOptionPB.field.name !== expected) {
    throw Error('Expect field name:' + expected + 'but receive:' + typeOptionPB.field.name);
  }
}

export async function assertNumberOfFields(viewId: string, expected: number) {
  const svc = new DatabaseBackendService(viewId);
  const databasePB = await svc.openDatabase().then((result) => result.unwrap());
  if (databasePB.fields.length !== expected) {
    throw Error('Expect number of fields:' + expected + 'but receive:' + databasePB.fields.length);
  }
}

export async function assertNumberOfRows(viewId: string, expected: number) {
  const svc = new DatabaseBackendService(viewId);
  const databasePB = await svc.openDatabase().then((result) => result.unwrap());
  if (databasePB.rows.length !== expected) {
    throw Error('Expect number of rows:' + expected + 'but receive:' + databasePB.rows.length);
  }
}
