import { YDatabase, YDatabaseRow, YDoc, YjsDatabaseKey, YjsEditorKey } from '@/application/collab.type';
import { Row } from '@/application/database-yjs/selector';
import { createContext, useContext } from 'react';
import * as Y from 'yjs';

export interface DatabaseContextState {
  readOnly: boolean;
  databaseDoc: YDoc;
  viewId: string;
  rowDocMap: Y.Map<YDoc>;
  isDatabaseRowPage?: boolean;
  navigateToRow?: (rowId: string) => void;
}

export const DatabaseContext = createContext<DatabaseContextState | null>(null);

export const useDatabase = () => {
  const database = useContext(DatabaseContext)
    ?.databaseDoc?.getMap(YjsEditorKey.data_section)
    .get(YjsEditorKey.database) as YDatabase;

  return database;
};

export function useDatabaseViewId() {
  return useContext(DatabaseContext)?.viewId;
}

export const useNavigateToRow = () => {
  return useContext(DatabaseContext)?.navigateToRow;
};

export const useRowDocMap = () => {
  return useContext(DatabaseContext)?.rowDocMap;
};

export const useIsDatabaseRowPage = () => {
  return useContext(DatabaseContext)?.isDatabaseRowPage;
};

export const useRow = (rowId: string) => {
  const rows = useRowDocMap();

  return rows?.get(rowId)?.getMap(YjsEditorKey.data_section);
};

export const useRowData = (rowId: string) => {
  return useRow(rowId)?.get(YjsEditorKey.database_row) as YDatabaseRow;
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

  return viewId ? database?.get(YjsDatabaseKey.views)?.get(viewId) : undefined;
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
