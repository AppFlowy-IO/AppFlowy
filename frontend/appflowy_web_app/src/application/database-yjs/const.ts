import { YDatabaseRow, YDoc, YjsDatabaseKey, YjsEditorKey } from '@/application/collab.type';
import * as Y from 'yjs';

export const DEFAULT_ROW_HEIGHT = 37;
export const MIN_COLUMN_WIDTH = 100;

export const getCell = (rowId: string, fieldId: string, rowMetas: Y.Map<YDoc>) => {
  const rowMeta = rowMetas.get(rowId);
  const meta = rowMeta?.getMap(YjsEditorKey.data_section).get(YjsEditorKey.database_row) as YDatabaseRow;

  return meta?.get(YjsDatabaseKey.cells)?.get(fieldId);
};

export const getCellData = (rowId: string, fieldId: string, rowMetas: Y.Map<YDoc>) => {
  return getCell(rowId, fieldId, rowMetas)?.get(YjsDatabaseKey.data);
};
