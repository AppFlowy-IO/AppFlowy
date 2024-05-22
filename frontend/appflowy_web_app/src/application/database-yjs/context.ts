import { YDatabase, YDatabaseRow, YDoc, YjsDatabaseKey, YjsEditorKey } from '@/application/collab.type';
import { Row } from '@/application/database-yjs/selector';
import { createContext, useContext } from 'react';
import * as Y from 'yjs';

export interface DatabaseContextState {
  readOnly: boolean;
  doc: YDoc;
  viewId: string;
  rowDocMap: Y.Map<YDoc>;
}

export const DatabaseContext = createContext<DatabaseContextState | null>(null);

export const useDatabase = () => {
  const database = useContext(DatabaseContext)
    ?.doc?.getMap(YjsEditorKey.data_section)
    .get(YjsEditorKey.database) as YDatabase;

  return database;
};

export const useRowMeta = (rowId: string) => {
  const rows = useContext(DatabaseContext)?.rowDocMap;
  const rowMetaDoc = rows?.get(rowId);
  const rowMeta = rowMetaDoc?.getMap(YjsEditorKey.data_section).get(YjsEditorKey.database_row) as YDatabaseRow;

  return rowMeta;
};

export const useViewId = () => {
  const context = useContext(DatabaseContext);

  return context?.viewId;
};

export const useReadOnly = () => {
  const context = useContext(DatabaseContext);

  return context?.readOnly;
};

export const useDatabaseView = () => {
  const database = useDatabase();
  const viewId = useViewId();

  return viewId ? database.get(YjsDatabaseKey.views)?.get(viewId) : undefined;
};

export function useDatabaseFields() {
  const database = useDatabase();

  return database.get(YjsDatabaseKey.fields);
}

export interface RowsState {
  rowOrders: Row[];
}

export const RowsContext = createContext<RowsState | null>(null);

export function useRowsContext() {
  return useContext(RowsContext);
}

export function useRows() {
  return useRowsContext()?.rowOrders;
}
