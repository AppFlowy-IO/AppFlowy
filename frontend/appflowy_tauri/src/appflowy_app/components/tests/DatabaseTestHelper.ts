import {
  FieldType,
  SingleSelectTypeOptionPB,
  ViewLayoutPB,
  ViewPB,
  WorkspaceSettingPB,
} from '../../../services/backend';
import { FolderEventGetCurrentWorkspace } from '../../../services/backend/events/flowy-folder2';
import { AppBackendService } from '../../stores/effects/folder/app/app_bd_svc';
import { DatabaseController } from '../../stores/effects/database/database_controller';
import { RowInfo } from '../../stores/effects/database/row/row_cache';
import { RowController } from '../../stores/effects/database/row/row_controller';
import {
  CellControllerBuilder,
  CheckboxCellController,
  DateCellController,
  NumberCellController,
  SelectOptionCellController,
  TextCellController,
  URLCellController,
} from '../../stores/effects/database/cell/controller_builder';
import { None, Option, Some } from 'ts-results';
import { TypeOptionBackendService } from '../../stores/effects/database/field/type_option/type_option_bd_svc';
import { DatabaseBackendService } from '../../stores/effects/database/database_bd_svc';
import { FieldInfo } from '../../stores/effects/database/field/field_controller';
import { TypeOptionController } from '../../stores/effects/database/field/type_option/type_option_controller';
import { makeSingleSelectTypeOptionContext } from '../../stores/effects/database/field/type_option/type_option_context';
import { SelectOptionBackendService } from '../../stores/effects/database/cell/select_option_bd_svc';
import { Log } from '$app/utils/log';

// Create a database view for specific layout type
// Do not use it production code. Just for testing
export async function createTestDatabaseView(layout: ViewLayoutPB): Promise<ViewPB> {
  const workspaceSetting: WorkspaceSettingPB = await FolderEventGetCurrentWorkspace().then((result) => result.unwrap());
  const appService = new AppBackendService(workspaceSetting.workspace.id);
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

export async function makeCheckboxCellController(
  fieldId: string,
  rowInfo: RowInfo,
  databaseController: DatabaseController
): Promise<Option<CheckboxCellController>> {
  const builder = await makeCellControllerBuilder(fieldId, rowInfo, FieldType.Checkbox, databaseController).then(
    (result) => result.unwrap()
  );
  return Some(builder.build() as CheckboxCellController);
}

export async function makeURLCellController(
  fieldId: string,
  rowInfo: RowInfo,
  databaseController: DatabaseController
): Promise<Option<URLCellController>> {
  const builder = await makeCellControllerBuilder(fieldId, rowInfo, FieldType.DateTime, databaseController).then(
    (result) => result.unwrap()
  );
  return Some(builder.build() as URLCellController);
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

export async function assertNumberOfRowsInGroup(viewId: string, groupId: string, expected: number) {
  const svc = new DatabaseBackendService(viewId);
  await svc.openDatabase();

  const group = await svc.getGroup(groupId).then((result) => result.unwrap());
  if (group.rows.length !== expected) {
    throw Error('Expect number of rows in group:' + expected + 'but receive:' + group.rows.length);
  }
}

export async function createSingleSelectOptions(viewId: string, fieldInfo: FieldInfo, optionNames: string[]) {
  assert(fieldInfo.field.field_type === FieldType.SingleSelect, 'Only work on single select');
  const typeOptionController = new TypeOptionController(viewId, Some(fieldInfo));
  const singleSelectTypeOptionContext = makeSingleSelectTypeOptionContext(typeOptionController);
  const singleSelectTypeOptionPB: SingleSelectTypeOptionPB = await singleSelectTypeOptionContext
    .getTypeOption()
    .then((result) => result.unwrap());

  const backendSvc = new SelectOptionBackendService(viewId, fieldInfo.field.id);
  for (const optionName of optionNames) {
    const option = await backendSvc.createOption({ name: optionName }).then((result) => result.unwrap());
    singleSelectTypeOptionPB.options.splice(0, 0, option);
  }
  await singleSelectTypeOptionContext.setTypeOption(singleSelectTypeOptionPB);
  return singleSelectTypeOptionContext;
}

export function assert(condition: boolean, msg?: string) {
  if (!condition) {
    throw Error(msg);
  }
}
