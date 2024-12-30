import * as Y from 'yjs';
import { YDatabaseCell, YjsDatabaseKey } from '@/application/types';
import { FieldType } from '@/application/database-yjs';

export function withTestingDateCell() {
  const cell = new Y.Map() as YDatabaseCell;

  cell.set(YjsDatabaseKey.id, 'date_field');
  cell.set(YjsDatabaseKey.data, Date.now());
  cell.set(YjsDatabaseKey.field_type, Number(FieldType.DateTime));
  cell.set(YjsDatabaseKey.created_at, Date.now());
  cell.set(YjsDatabaseKey.last_modified, Date.now());
  cell.set(YjsDatabaseKey.end_timestamp, Date.now() + 1000);
  cell.set(YjsDatabaseKey.include_time, true);
  cell.set(YjsDatabaseKey.is_range, true);
  cell.set(YjsDatabaseKey.reminder_id, 'reminderId');

  return cell;
}

export function withTestingCheckboxCell() {
  const cell = new Y.Map() as YDatabaseCell;

  cell.set(YjsDatabaseKey.id, 'checkbox_field');
  cell.set(YjsDatabaseKey.data, 'Yes');
  cell.set(YjsDatabaseKey.field_type, Number(FieldType.Checkbox));
  cell.set(YjsDatabaseKey.created_at, Date.now());
  cell.set(YjsDatabaseKey.last_modified, Date.now());

  return cell;
}

export function withTestingSingleOptionCell() {
  const cell = new Y.Map() as YDatabaseCell;

  cell.set(YjsDatabaseKey.id, 'single_select_field');
  cell.set(YjsDatabaseKey.data, 'optionId');
  cell.set(YjsDatabaseKey.field_type, Number(FieldType.SingleSelect));
  cell.set(YjsDatabaseKey.created_at, Date.now());
  cell.set(YjsDatabaseKey.last_modified, Date.now());

  return cell;
}
