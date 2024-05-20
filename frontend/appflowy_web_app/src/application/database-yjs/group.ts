import { YDatabaseField, YDatabaseRow, YDoc, YjsDatabaseKey, YjsEditorKey } from '@/application/collab.type';
import { FieldType } from '@/application/database-yjs/database.type';
import { parseSelectOptionTypeOptions } from '@/application/database-yjs/fields';
import { Row } from '@/application/database-yjs/selector';
import * as Y from 'yjs';

export function groupByField(rows: Row[], rowMetas: Y.Map<YDoc>, field: YDatabaseField) {
  const fieldType = Number(field.get(YjsDatabaseKey.type));
  const isSelectOptionField = [FieldType.SingleSelect, FieldType.MultiSelect].includes(fieldType);

  if (!isSelectOptionField) return;
  return groupBySelectOption(rows, rowMetas, field);
}

function getCellData(rowId: string, fieldId: string, rowMetas: Y.Map<YDoc>) {
  const rowMeta = rowMetas.get(rowId);
  const meta = rowMeta?.getMap(YjsEditorKey.data_section).get(YjsEditorKey.database_row) as YDatabaseRow;

  return meta?.get(YjsDatabaseKey.cells)?.get(fieldId)?.get(YjsDatabaseKey.data);
}

export function groupBySelectOption(rows: Row[], rowMetas: Y.Map<YDoc>, field: YDatabaseField) {
  const fieldId = field.get(YjsDatabaseKey.id);
  const result = new Map<string, Row[]>();
  const typeOption = parseSelectOptionTypeOptions(field);

  if (!typeOption) {
    return;
  }

  if (typeOption.options.length === 0) {
    result.set(fieldId, rows);
    return result;
  }

  rows.forEach((row) => {
    const cellData = getCellData(row.id, fieldId, rowMetas);

    const selectedIds = (cellData as string)?.split(',') ?? [];

    if (selectedIds.length === 0) {
      const group = result.get(fieldId) ?? [];

      group.push(row);
      result.set(fieldId, group);
      return;
    }

    selectedIds.forEach((id) => {
      const option = typeOption.options.find((option) => option.id === id);
      const groupName = option?.id ?? fieldId;
      const group = result.get(groupName) ?? [];

      group.push(row);
      result.set(groupName, group);
    });
  });

  return result;
}
