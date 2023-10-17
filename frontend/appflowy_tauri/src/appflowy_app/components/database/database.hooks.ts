import { RefObject, createContext, createRef, useContext, useCallback, useMemo, useEffect } from 'react';
import { useSearchParams } from 'react-router-dom';
import { proxy, useSnapshot } from 'valtio';
import { DatabaseLayoutPB, DatabaseNotification } from '@/services/backend';
import { subscribeNotifications } from '$app/hooks';
import {
  Database,
  databaseService,
  fieldService,
  rowListeners,
  sortListeners,
} from './application';

const VerticalScrollElementRefContext = createContext<RefObject<Element>>(createRef());

export const VerticalScrollElementProvider = VerticalScrollElementRefContext.Provider;
export const useVerticalScrollElement = () => useContext(VerticalScrollElementRefContext);

export function useSelectDatabaseView() {
  const key = 'v';
  const [searchParams, setSearchParams] = useSearchParams();

  const selectedViewId = useMemo(() => searchParams.get(key), [searchParams]);

  const selectViewId = useCallback((value: string) => {
    setSearchParams({ [key]: value });
  }, [setSearchParams]);

  return [selectedViewId, selectViewId] as const;
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

    void databaseService.openDatabase(viewId).then(value => Object.assign(proxyDatabase, value));

    return proxyDatabase;
  }, [viewId]);

  useEffect(() => {
    const unsubscribePromise = subscribeNotifications({
      [DatabaseNotification.DidUpdateFields]: async () => {
        database.fields = await fieldService.getFields(viewId);
      },

      [DatabaseNotification.DidUpdateViewRows]: changeset => rowListeners.didUpdateViewRows(database, changeset),
      [DatabaseNotification.DidReorderRows]: changeset => rowListeners.didReorderRows(database, changeset),
      [DatabaseNotification.DidReorderSingleRow]: changeset => rowListeners.didReorderSingleRow(database, changeset),

      [DatabaseNotification.DidUpdateSort]: changeset => sortListeners.didUpdateSort(database, changeset),
    }, { id: viewId });

    return () => void unsubscribePromise.then(unsubscribe => unsubscribe());
  }, [viewId, database]);

  return database;
};
