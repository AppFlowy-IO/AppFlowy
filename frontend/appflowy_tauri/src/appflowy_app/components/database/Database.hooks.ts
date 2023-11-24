import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { proxy, useSnapshot } from 'valtio';
import { DatabaseLayoutPB, DatabaseNotification, FieldVisibility } from '@/services/backend';
import { subscribeNotifications } from '$app/hooks';
import { Database, databaseService, fieldListeners, fieldService, rowListeners, sortListeners } from './application';
import { didUpdateFilter } from '$app/components/database/application/filter/filter_listeners';
import { didUpdateViewRowsVisibility } from '$app/components/database/application/row/row_listeners';

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
});

export const DatabaseProvider = DatabaseContext.Provider;

export const useDatabase = () => useSnapshot(useContext(DatabaseContext));

export const useDatabaseVisibilityRows = () => {
  const { rowMetas } = useDatabase();

  return useMemo(() => rowMetas.filter((row) => !row.isHidden), [rowMetas]);
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
    });

    void databaseService.openDatabase(viewId).then((value) => Object.assign(proxyDatabase, value));

    return proxyDatabase;
  }, [viewId]);

  useEffect(() => {
    const unsubscribePromise = subscribeNotifications(
      {
        [DatabaseNotification.DidUpdateFields]: async () => {
          database.fields = await fieldService.getFields(viewId);
        },
        [DatabaseNotification.DidUpdateFieldSettings]: async (changeset) => {
          fieldListeners.didUpdateFieldSettings(database, changeset);
        },
        [DatabaseNotification.DidUpdateViewRows]: (changeset) => {
          rowListeners.didUpdateViewRows(database, changeset);
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
          didUpdateFilter(database, changeset);
        },
        [DatabaseNotification.DidUpdateViewRowsVisibility]: (changeset) => {
          didUpdateViewRowsVisibility(database, changeset);
        },
      },
      { id: viewId }
    );

    return () => void unsubscribePromise.then((unsubscribe) => unsubscribe());
  }, [viewId, database]);

  return database;
};

export function useDatabaseResize() {
  const ref = useRef<HTMLDivElement>(null);
  const collectionRef = useRef<HTMLDivElement>(null);

  const [tableHeight, setTableHeight] = useState(0);

  useEffect(() => {
    const element = ref.current;

    if (!element) return;

    const collectionElement = collectionRef.current;
    const handleResize = () => {
      const rect = element.getBoundingClientRect();
      const collectionRect = collectionElement?.getBoundingClientRect();
      let height = rect.height - 31;

      if (collectionRect) {
        height -= collectionRect.height;
      }

      setTableHeight(height);
    };

    handleResize();
    const resizeObserver = new ResizeObserver(() => {
      handleResize();
    });

    resizeObserver.observe(element);
    if (collectionElement) {
      resizeObserver.observe(collectionRef.current);
    }

    return () => {
      resizeObserver.disconnect();
    };
  }, []);

  return {
    ref,
    collectionRef,
    tableHeight,
  };
}
