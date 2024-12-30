import {
  RowId,
  YDatabaseCell,
  YDatabaseCells,
  YDatabaseRow,
  YDoc,
  YjsDatabaseKey,
  YjsEditorKey,
} from '@/application/types';
import { FieldType, Row } from '@/application/database-yjs';
import * as Y from 'yjs';
import * as rowsJson from './fixtures/rows.json';

export function withTestingRows (): Row[] {
  return rowsJson.map((row) => {
    return {
      id: row.id,
      height: 37,
    };
  });
}

export function withTestingRowDataMap (): Record<RowId, YDoc> {
  const folder: Record<RowId, YDoc> = {};
  const rows = withTestingRows();

  rows.forEach((row, index) => {
    const rowDoc = new Y.Doc();
    const rowData = withTestingRowData(row.id, index);

    rowDoc.getMap(YjsEditorKey.data_section).set(YjsEditorKey.database_row, rowData);
    folder[row.id] = rowDoc;
  });

  return folder;
}

export function withTestingRowData (id: string, index: number) {
  const rowData = new Y.Map() as YDatabaseRow;

  rowData.set(YjsDatabaseKey.id, id);
  rowData.set(YjsDatabaseKey.height, 37);
  rowData.set(YjsDatabaseKey.last_modified, Date.now() + index * 1000);
  rowData.set(YjsDatabaseKey.created_at, Date.now() + index * 1000);

  const cells = new Y.Map() as YDatabaseCells;

  const textFieldCell = withTestingCell(rowsJson[index].cells.text_field.data);

  textFieldCell.set(YjsDatabaseKey.field_type, Number(FieldType.RichText));
  cells.set('text_field', textFieldCell);

  const numberFieldCell = withTestingCell(rowsJson[index].cells.number_field.data);

  numberFieldCell.set(YjsDatabaseKey.field_type, Number(FieldType.Number));
  cells.set('number_field', numberFieldCell);

  const checkboxFieldCell = withTestingCell(rowsJson[index].cells.checkbox_field.data);

  checkboxFieldCell.set(YjsDatabaseKey.field_type, Number(FieldType.Checkbox));
  cells.set('checkbox_field', checkboxFieldCell);

  const dateTimeFieldCell = withTestingCell(rowsJson[index].cells.date_field.data);

  dateTimeFieldCell.set(YjsDatabaseKey.field_type, Number(FieldType.DateTime));
  cells.set('date_field', dateTimeFieldCell);

  const urlFieldCell = withTestingCell(rowsJson[index].cells.url_field.data);

  urlFieldCell.set(YjsDatabaseKey.field_type, Number(FieldType.URL));
  cells.set('url_field', urlFieldCell);

  const singleSelectFieldCell = withTestingCell(rowsJson[index].cells.single_select_field.data);

  singleSelectFieldCell.set(YjsDatabaseKey.field_type, Number(FieldType.SingleSelect));
  cells.set('single_select_field', singleSelectFieldCell);

  const multiSelectFieldCell = withTestingCell(rowsJson[index].cells.multi_select_field.data);

  multiSelectFieldCell.set(YjsDatabaseKey.field_type, Number(FieldType.MultiSelect));
  cells.set('multi_select_field', multiSelectFieldCell);

  const checlistFieldCell = withTestingCell(rowsJson[index].cells.checklist_field.data);

  checlistFieldCell.set(YjsDatabaseKey.field_type, Number(FieldType.Checklist));
  cells.set('checklist_field', checlistFieldCell);

  rowData.set(YjsDatabaseKey.cells, cells);
  return rowData;
}

export function withTestingCell (cellData: string | number) {
  const cell = new Y.Map() as YDatabaseCell;

  cell.set(YjsDatabaseKey.data, cellData);
  return cell;
}
