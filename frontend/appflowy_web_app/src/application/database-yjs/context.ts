import { YDatabase, YDatabaseRow, YDoc, YjsDatabaseKey, YjsEditorKey } from '@/application/collab.type';
import { filterBy } from '@/application/database-yjs/filter';
import { Row } from '@/application/database-yjs/selector';
import { sortBy } from '@/application/database-yjs/sort';
import { createContext, useContext, useEffect, useState } from 'react';
import * as Y from 'yjs';
import debounce from 'lodash-es/debounce';

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

export interface GridRowsState {
  rowOrders: Row[];
}

export const GridRowsContext = createContext<GridRowsState | null>(null);

export function useGridRowsContext() {
  return useContext(GridRowsContext);
}

export function useGridRows() {
  return useGridRowsContext()?.rowOrders;
}

export function useGridRowOrders() {
  const rows = useContext(DatabaseContext)?.rowDocMap;
  const [rowOrders, setRowOrders] = useState<Row[]>();
  const view = useDatabaseView();
  const sorts = view?.get(YjsDatabaseKey.sorts);
  const fields = useDatabaseFields();
  const filters = view?.get(YjsDatabaseKey.filters);

  useEffect(() => {
    const onConditionsChange = () => {
      const originalRowOrders = view?.get(YjsDatabaseKey.row_orders).toJSON();

      if (!originalRowOrders || !rows) return;

      console.log('sort or filter changed');
      if (sorts?.length === 0 && filters?.length === 0) {
        setRowOrders(originalRowOrders);
        return;
      }

      let rowOrders: Row[] | undefined;

      if (sorts?.length) {
        rowOrders = sortBy(originalRowOrders, sorts, fields, rows);
      }

      if (filters?.length) {
        rowOrders = filterBy(rowOrders ?? originalRowOrders, filters, fields, rows);
      }

      if (rowOrders) {
        setRowOrders(rowOrders);
      } else {
        setRowOrders(originalRowOrders);
      }
    };

    const debounceConditionsChange = debounce(onConditionsChange, 200);

    onConditionsChange();
    sorts?.observeDeep(debounceConditionsChange);
    filters?.observeDeep(debounceConditionsChange);
    fields?.observeDeep(debounceConditionsChange);
    rows?.observeDeep(debounceConditionsChange);

    return () => {
      sorts?.unobserveDeep(debounceConditionsChange);
      filters?.unobserveDeep(debounceConditionsChange);
      fields?.unobserveDeep(debounceConditionsChange);
      rows?.observeDeep(debounceConditionsChange);
    };
  }, [fields, rows, sorts, filters, view]);

  return rowOrders;
}
