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
  scrollLeft?: number;
  isDocumentBlock?: boolean;
  navigateToRow?: (rowId: string) => void;
  loadView?: LoadView;
  createRowDoc?: CreateRowDoc;
  loadViewMeta?: LoadViewMeta;
  navigateToView?: (viewId: string, blockId?: string) => Promise<void>;
  onRendered?: (height: number) => void;
  showActions?: boolean;
}

export const DatabaseContext = createContext<DatabaseContextState | null>(null);

export const useDatabaseContext = () => {
  const context = useContext(DatabaseContext);

  if (!context) {
    throw new Error('DatabaseContext is not provided');
  }

  return context;
};

export const useDatabase = () => {
  const database = useDatabaseContext()
    .databaseDoc?.getMap(YjsEditorKey.data_section)
    .get(YjsEditorKey.database) as YDatabase;

  return database;
};

export const useNavigateToRow = () => {
  return useDatabaseContext().navigateToRow;
};

export const useRowDocMap = () => {
  return useDatabaseContext().rowDocMap;
};

export const useIsDatabaseRowPage = () => {
  return useDatabaseContext().isDatabaseRowPage;
};

export const useRow = (rowId: string) => {
  const rows = useRowDocMap();

  return rows?.[rowId]?.getMap(YjsEditorKey.data_section);
};

export const useRowData = (rowId: string) => {
  return useRow(rowId)?.get(YjsEditorKey.database_row) as YDatabaseRow;
};

export const useDatabaseViewId = () => {
  const context = useDatabaseContext();

  return context?.viewId;
};

export const useReadOnly = () => {
  const context = useDatabaseContext();

  return context?.readOnly || true;
};

export const useDatabaseView = () => {
  const database = useDatabase();
  const viewId = useDatabaseViewId();

  return viewId ? database?.get(YjsDatabaseKey.views)?.get(viewId) : undefined;
};

export function useDatabaseFields () {
  const database = useDatabase();

  return database.get(YjsDatabaseKey.fields);
}

export const useDatabaseSelectedView = (viewId: string) => {
  const database = useDatabase();

  return database.get(YjsDatabaseKey.views).get(viewId);
};