import { YDatabaseRow, YDoc, YjsDatabaseKey, YjsEditorKey } from '@/application/collab.type';
import { RowMetaKey } from '@/application/database-yjs/database.type';
import * as Y from 'yjs';
import { v5 as uuidv5, parse as uuidParse } from 'uuid';

export const DEFAULT_ROW_HEIGHT = 36;
export const MIN_COLUMN_WIDTH = 100;

export const getCell = (rowId: string, fieldId: string, rowMetas: Y.Map<YDoc>) => {
  const rowMeta = rowMetas.get(rowId);
  const meta = rowMeta?.getMap(YjsEditorKey.data_section).get(YjsEditorKey.database_row) as YDatabaseRow;

  return meta?.get(YjsDatabaseKey.cells)?.get(fieldId);
};

export const getCellData = (rowId: string, fieldId: string, rowMetas: Y.Map<YDoc>) => {
  return getCell(rowId, fieldId, rowMetas)?.get(YjsDatabaseKey.data);
};

export const metaIdFromRowId = (rowId: string) => {
  const namespace = uuidParse(rowId);

  return (key: RowMetaKey) => uuidv5(key, namespace).toString();
};
