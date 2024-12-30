import { RowId, YDatabaseRow, YDoc, YjsDatabaseKey, YjsEditorKey } from '@/application/types';
import { RowMetaKey } from '@/application/database-yjs/database.type';
import { v5 as uuidv5, parse as uuidParse } from 'uuid';

export const DEFAULT_ROW_HEIGHT = 36;
export const MIN_COLUMN_WIDTH = 150;

export const getCell = (rowId: string, fieldId: string, rowMetas: Record<RowId, YDoc>) => {
  const rowMeta = rowMetas[rowId];

  const meta = rowMeta?.getMap(YjsEditorKey.data_section).get(YjsEditorKey.database_row) as YDatabaseRow;

  return meta?.get(YjsDatabaseKey.cells)?.get(fieldId);
};

export const getCellData = (rowId: string, fieldId: string, rowMetas: Record<RowId, YDoc>) => {
  return getCell(rowId, fieldId, rowMetas)?.get(YjsDatabaseKey.data);
};

export const metaIdFromRowId = (rowId: string) => {
  let namespace: Uint8Array;

  try {
    namespace = uuidParse(rowId);
  } catch (e) {
    namespace = uuidParse(generateUUID());
  }

  return (key: RowMetaKey) => uuidv5(key, namespace).toString();
};

export const generateUUID = () => uuidv5(Date.now().toString(), uuidv5.URL);
