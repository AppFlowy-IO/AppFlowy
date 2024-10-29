import {
  CreateRowDoc,
  LoadView,
  LoadViewMeta, RowId,
  YDatabase,
  YDatabaseRow,
  YDoc,
  YjsDatabaseKey,
  YjsEditorKey,
} from '@/application/types';
import { createContext, useContext } from 'react';

export interface DatabaseContextState {
  readOnly: boolean;
  databaseDoc: YDoc;
  iidIndex: string;
  viewId: string;
  rowDocMap: Record<RowId, YDoc> | null;
  isDatabaseRowPage?: boolean;
  navigateToRow?: (rowId: string) => void;
  loadView?: LoadView;
  createRowDoc?: CreateRowDoc;
  loadViewMeta?: LoadViewMeta;
  navigateToView?: (viewId: string, blockId?: string) => Promise<void>;
}

export const DatabaseContext = createContext<DatabaseContextState | null>(null);

export const useDatabase = () => {
  const database = useContext(DatabaseContext)
    ?.databaseDoc?.getMap(YjsEditorKey.data_section)
    .get(YjsEditorKey.database) as YDatabase;

  return database;
};

export function useDatabaseViewId () {
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

  return rows?.[rowId]?.getMap(YjsEditorKey.data_section);
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

export function useDatabaseFields () {
  const database = useDatabase();

  return database.get(YjsDatabaseKey.fields);
}
