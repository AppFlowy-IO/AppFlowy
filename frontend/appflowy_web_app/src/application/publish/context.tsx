import { GetViewRowsMap, LoadView, LoadViewMeta } from '@/application/collab.type';
import { db } from '@/application/db';
import { ViewMeta } from '@/application/db/tables/view_metas';
import { AFConfigContext } from '@/components/app/AppConfig';
import { useLiveQuery } from 'dexie-react-hooks';
import { createContext, useCallback, useContext, useEffect, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';

export interface PublishContextType {
  namespace: string;
  publishName: string;
  viewMeta?: ViewMeta;
  toView: (viewId: string) => Promise<void>;
  loadViewMeta: LoadViewMeta;
  getViewRowsMap?: GetViewRowsMap;

  loadView: LoadView;
}

export const PublishContext = createContext<PublishContextType | null>(null);

export const PublishProvider = ({
  children,
  namespace,
  publishName,
}: {
  children: React.ReactNode;
  namespace: string;
  publishName: string;
}) => {
  const viewMeta = useLiveQuery(async () => {
    const name = `${namespace}_${publishName}`;

    return db.view_metas.get(name);
  }, [namespace, publishName]);
  const [subscribers, setSubscribers] = useState<Map<string, (meta: ViewMeta) => void>>(new Map());

  useEffect(() => {
    return () => {
      setSubscribers(new Map());
    };
  }, []);
  useEffect(() => {
    db.view_metas.hook('creating', (primaryKey, obj) => {
      const subscriber = subscribers.get(primaryKey);

      subscriber?.(obj);

      return obj;
    });
    db.view_metas.hook('deleting', (primaryKey, obj) => {
      const subscriber = subscribers.get(primaryKey);

      subscriber?.(obj);

      return;
    });
    db.view_metas.hook('updating', (modifications, primaryKey, obj) => {
      const subscriber = subscribers.get(primaryKey);

      subscriber?.({
        ...obj,
        ...modifications,
      });

      return modifications;
    });
  }, [subscribers]);

  const prevViewMeta = useRef(viewMeta);

  const service = useContext(AFConfigContext)?.service;
  const navigate = useNavigate();
  const toView = useCallback(
    async (viewId: string) => {
      try {
        const res = await service?.getPublishInfo(viewId);

        if (!res) {
          throw new Error('Not found');
        }

        const { namespace, publishName } = res;

        navigate(`/${namespace}/${publishName}`);
      } catch (e) {
        return Promise.reject(e);
      }
    },
    [navigate, service]
  );

  const loadViewMeta = useCallback(
    async (viewId: string, callback?: (meta: ViewMeta) => void) => {
      try {
        const info = await service?.getPublishInfo(viewId);

        if (!info) {
          throw new Error('View has not been published yet');
        }

        const { namespace, publishName } = info;

        const name = `${namespace}_${publishName}`;

        const meta = await service?.getPublishViewMeta(namespace, publishName);

        if (!meta) {
          return Promise.reject(new Error('View meta has not been published yet'));
        }

        callback?.(meta);

        if (callback) {
          setSubscribers((prev) => {
            prev.set(name, callback);

            return prev;
          });
        }

        return meta;
      } catch (e) {
        return Promise.reject(e);
      }
    },
    [service]
  );

  const getViewRowsMap = useCallback(
    async (viewId: string, rowIds?: string[]) => {
      try {
        const info = await service?.getPublishInfo(viewId);

        if (!info) {
          throw new Error('View has not been published yet');
        }

        const { namespace, publishName } = info;
        const res = await service?.getPublishDatabaseViewRows(namespace, publishName, rowIds);

        if (!res) {
          throw new Error('View has not been published yet');
        }

        return res;
      } catch (e) {
        return Promise.reject(e);
      }
    },
    [service]
  );

  const loadView = useCallback(
    async (viewId: string) => {
      try {
        const res = await service?.getPublishInfo(viewId);

        if (!res) {
          throw new Error('View has not been published yet');
        }

        const { namespace, publishName } = res;

        const data = service?.getPublishView(namespace, publishName);

        if (!data) {
          throw new Error('View has not been published yet');
        }

        return data;
      } catch (e) {
        return Promise.reject(e);
      }
    },
    [service]
  );

  useEffect(() => {
    if (!viewMeta && prevViewMeta.current) {
      window.location.reload();
      return;
    }

    prevViewMeta.current = viewMeta;
  }, [viewMeta]);

  return (
    <PublishContext.Provider
      value={{
        loadView,
        viewMeta,
        getViewRowsMap,
        loadViewMeta,
        toView,
        namespace,
        publishName,
      }}
    >
      {children}
    </PublishContext.Provider>
  );
};

export function usePublishContext() {
  return useContext(PublishContext);
}
