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
import assert from 'assert';
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

export async function assertTextCell(rowInfo: RowInfo, databaseController: DatabaseController, expectedContent: string) {
  const cellController = await makeTextCellController(rowInfo, databaseController).then((result) => result.unwrap());
  cellController.subscribeChanged({
    onCellChanged: (value) => {
      const cellContent = value.unwrap();
      if (cellContent !== expectedContent) {
        throw Error();
      }
    },
  });
  cellController.getCellData();
}

export async function editTextCell(rowInfo: RowInfo, databaseController: DatabaseController, content: string) {
  const cellController = await makeTextCellController(rowInfo, databaseController).then((result) => result.unwrap());
  await cellController.saveCellData(content);
}

export async function makeTextCellController(
  rowInfo: RowInfo,
  databaseController: DatabaseController
): Promise<Option<TextCellController>> {
  const builder = await makeCellControllerBuilder(rowInfo, FieldType.RichText, databaseController).then((result) =>
    result.unwrap()
  );
  return Some(builder.build() as TextCellController);
}

export async function makeNumberCellController(
  rowInfo: RowInfo,
  databaseController: DatabaseController
): Promise<Option<NumberCellController>> {
  const builder = await makeCellControllerBuilder(rowInfo, FieldType.Number, databaseController).then((result) =>
    result.unwrap()
  );
  return Some(builder.build() as NumberCellController);
}

export async function makeSingleSelectCellController(
  rowInfo: RowInfo,
  databaseController: DatabaseController
): Promise<Option<SelectOptionCellController>> {
  const builder = await makeCellControllerBuilder(rowInfo, FieldType.SingleSelect, databaseController).then((result) =>
    result.unwrap()
  );
  return Some(builder.build() as SelectOptionCellController);
}

export async function makeDateCellController(
  rowInfo: RowInfo,
  databaseController: DatabaseController
): Promise<Option<DateCellController>> {
  const builder = await makeCellControllerBuilder(rowInfo, FieldType.DateTime, databaseController).then((result) =>
    result.unwrap()
  );
  return Some(builder.build() as DateCellController);
}

export async function makeCellControllerBuilder(
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
    if (cellIdentifier.fieldType === fieldType) {
      return Some(builder);
    }
  }

  return None;
}

export async function assertFieldName(viewId: string, fieldId: string, fieldType: FieldType, expected: string) {
  const svc = new TypeOptionBackendService(viewId);
  const typeOptionPB = await svc.getTypeOption(fieldId, fieldType).then((result) => result.unwrap());
  if (typeOptionPB.field.name !== expected) {
    throw Error();
  }
}

export async function assertNumberOfFields(viewId: string, expected: number) {
  const svc = new DatabaseBackendService(viewId);
  const databasePB = await svc.openDatabase().then((result) => result.unwrap());
  if (databasePB.fields.length !== expected) {
    throw Error();
  }
}
