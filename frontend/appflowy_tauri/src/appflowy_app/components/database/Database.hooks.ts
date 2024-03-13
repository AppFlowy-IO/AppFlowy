import { createContext, useCallback, useContext, useEffect, useMemo } from 'react';
import { useSearchParams } from 'react-router-dom';
import { proxy, useSnapshot } from 'valtio';

import { DatabaseLayoutPB, DatabaseNotification, FieldVisibility } from '@/services/backend';
import { subscribeNotifications } from '$app/application/notification';
import {
  Cell,
  Database,
  databaseService,
  cellListeners,
  fieldListeners,
  rowListeners,
  sortListeners,
  filterListeners,
} from '$app/application/database';

export function useSelectDatabaseView({ viewId }: { viewId?: string }) {
  const key = 'v';
  const [searchParams, setSearchParams] = useSearchParams();

  const selectedViewId = useMemo(() => searchParams.get(key) || viewId, [searchParams, viewId]);

  const onChange = useCallback(
    (value: string) => {
      setSearchParams({ [key]: value });
    },
    [setSearchParams]
  );

  return {
    selectedViewId,
    onChange,
  };
}

const DatabaseContext = createContext<Database>({
  id: '',
  isLinked: false,
  layoutType: DatabaseLayoutPB.Grid,
  fields: [],
  rowMetas: [],
  filters: [],
  sorts: [],
  groupSettings: [],
  groups: [],
  typeOptions: {},
  cells: {},
});

export const DatabaseProvider = DatabaseContext.Provider;

export const useDatabase = () => useSnapshot(useContext(DatabaseContext));

export const useSelectorCell = (rowId: string, fieldId: string) => {
  const database = useContext(DatabaseContext);
  const cells = useSnapshot(database.cells);

  return cells[`${rowId}:${fieldId}`];
};

export const useDispatchCell = () => {
  const database = useContext(DatabaseContext);

  const setCell = useCallback(
    (cell: Cell) => {
      const id = `${cell.rowId}:${cell.fieldId}`;

      database.cells[id] = cell;
    },
    [database]
  );

  const deleteCells = useCallback(
    ({ rowId, fieldId }: { rowId: string; fieldId?: string }) => {
      cellListeners.didDeleteCells({ database, rowId, fieldId });
    },
    [database]
  );

  return {
    deleteCells,
    setCell,
  };
};

export const useDatabaseSorts = () => {
  const context = useContext(DatabaseContext);

  return useSnapshot(context.sorts);
};

export const useSortsCount = () => {
  const { sorts } = useDatabase();

  return sorts?.length;
};

export const useFiltersCount = () => {
  const { filters, fields } = useDatabase();

  // filter fields: if the field is deleted, it will not be displayed
  return useMemo(
    () => filters?.map((filter) => fields.find((field) => field.id === filter.fieldId)).filter(Boolean).length,
    [filters, fields]
  );
};

export function useStaticTypeOption<T>(fieldId: string) {
  const context = useContext(DatabaseContext);
  const typeOptions = context.typeOptions;

  return typeOptions[fieldId] as T;
}

export function useTypeOption<T>(fieldId: string) {
  const context = useContext(DatabaseContext);
  const typeOptions = useSnapshot(context.typeOptions);

  return typeOptions[fieldId] as T;
}

export const useDatabaseVisibilityRows = () => {
  const { rowMetas } = useDatabase();

  return useMemo(() => rowMetas.filter((row) => row && !row.isHidden), [rowMetas]);
};

export const useDatabaseVisibilityFields = () => {
  const database = useDatabase();

  return useMemo(
    () => database.fields.filter((field) => field.visibility !== FieldVisibility.AlwaysHidden),
    [database.fields]
  );
};

export const useConnectDatabase = (viewId: string) => {
  const database = useMemo(() => {
    const proxyDatabase = proxy<Database>({
      id: '',
      isLinked: false,
      layoutType: DatabaseLayoutPB.Grid,
      fields: [],
      rowMetas: [],
      filters: [],
      sorts: [],
      groupSettings: [],
      groups: [],
      typeOptions: {},
      cells: {},
    });

    void databaseService.openDatabase(viewId).then((value) => Object.assign(proxyDatabase, value));

    return proxyDatabase;
  }, [viewId]);

  useEffect(() => {
    const unsubscribePromise = subscribeNotifications(
      {
        [DatabaseNotification.DidUpdateFields]: async (changeset) => {
          await fieldListeners.didUpdateFields(viewId, database, changeset);
        },
        [DatabaseNotification.DidUpdateFieldSettings]: (changeset) => {
          fieldListeners.didUpdateFieldSettings(database, changeset);
        },
        [DatabaseNotification.DidUpdateViewRows]: async (changeset) => {
          await rowListeners.didUpdateViewRows(viewId, database, changeset);
        },
        [DatabaseNotification.DidReorderRows]: (changeset) => {
          rowListeners.didReorderRows(database, changeset);
        },
        [DatabaseNotification.DidReorderSingleRow]: (changeset) => {
          rowListeners.didReorderSingleRow(database, changeset);
        },

        [DatabaseNotification.DidUpdateSort]: (changeset) => {
          sortListeners.didUpdateSort(database, changeset);
        },

        [DatabaseNotification.DidUpdateFilter]: (changeset) => {
          filterListeners.didUpdateFilter(database, changeset);
        },
        [DatabaseNotification.DidUpdateViewRowsVisibility]: async (changeset) => {
          await rowListeners.didUpdateViewRowsVisibility(viewId, database, changeset);
        },
      },
      { id: viewId }
    );

    return () => void unsubscribePromise.then((unsubscribe) => unsubscribe());
  }, [viewId, database]);

  return database;
};

const DatabaseRenderedContext = createContext<(viewId: string) => void>(() => {
  return;
});

export const DatabaseRenderedProvider = DatabaseRenderedContext.Provider;

export const useDatabaseRendered = () => useContext(DatabaseRenderedContext);
