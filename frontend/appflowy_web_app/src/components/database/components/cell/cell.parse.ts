import { YDatabaseCell, YjsDatabaseKey } from '@/application/collab.type';
import { FieldType } from '@/application/database-yjs/database.type';
import { Cell, CheckboxCell, DateTimeCell } from './cell.type';

export function parseYDatabaseCommonCellToCell(cell: YDatabaseCell): Cell {
  return {
    createdAt: Number(cell.get(YjsDatabaseKey.created_at)),
    lastModified: Number(cell.get(YjsDatabaseKey.last_modified)),
    fieldType: parseInt(cell.get(YjsDatabaseKey.field_type)) as FieldType,
    data: cell.get(YjsDatabaseKey.data),
  };
}

export function parseYDatabaseCellToCell(cell: YDatabaseCell): Cell {
  const fieldType = parseInt(cell.get(YjsDatabaseKey.field_type));

  if (fieldType === FieldType.DateTime) {
    return parseYDatabaseDateTimeCellToCell(cell);
  }

  if (fieldType === FieldType.Checkbox) {
    return parseYDatabaseCheckboxCellToCell(cell);
  }

  return parseYDatabaseCommonCellToCell(cell);
}

export function parseYDatabaseDateTimeCellToCell(cell: YDatabaseCell): DateTimeCell {
  return {
    ...parseYDatabaseCommonCellToCell(cell),
    data: cell.get(YjsDatabaseKey.data) as string,
    fieldType: FieldType.DateTime,
    endTimestamp: cell.get(YjsDatabaseKey.end_timestamp),
    includeTime: cell.get(YjsDatabaseKey.include_time),
    isRange: cell.get(YjsDatabaseKey.is_range),
    reminderId: cell.get(YjsDatabaseKey.reminder_id),
  };
}

export function parseYDatabaseCheckboxCellToCell(cell: YDatabaseCell): CheckboxCell {
  return {
    ...parseYDatabaseCommonCellToCell(cell),
    data: cell.get(YjsDatabaseKey.data) === 'Yes',
    fieldType: FieldType.Checkbox,
  };
}
