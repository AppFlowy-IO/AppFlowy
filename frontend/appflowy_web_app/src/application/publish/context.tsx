import { YDoc } from '@/application/collab.type';
import { db } from '@/application/db';
import { ViewMeta } from '@/application/db/tables/view_metas';
import { notify } from '@/components/_shared/notify';
import { AFConfigContext } from '@/components/app/AppConfig';
import { useLiveQuery } from 'dexie-react-hooks';
import { createContext, useCallback, useContext } from 'react';
import { useNavigate } from 'react-router-dom';
import * as Y from 'yjs';

export interface PublishContextType {
  namespace: string;
  publishName: string;
  viewMeta?: ViewMeta;
  toView: (viewId: string) => Promise<void>;
  loadViewMeta: (viewId: string) => Promise<ViewMeta>;
  getViewRowsMap?: (viewId: string, rowIds: string[]) => Promise<{ rows: Y.Map<YDoc>; destroy: () => void }>;

  loadView: (viewId: string) => Promise<YDoc>;
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
  });
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
        notify.error('The view has not been published yet.');
        return Promise.reject(e);
      }
    },
    [navigate, service]
  );

  const loadViewMeta = useCallback(
    async (viewId: string) => {
      try {
        const info = await service?.getPublishInfo(viewId);

        if (!info) {
          throw new Error('View has not been published yet');
        }

        const res = await service?.getPublishViewMeta(namespace, publishName);

        if (!res) {
          throw new Error('View has not been published yet');
        }

        return res;
      } catch (e) {
        return Promise.reject(e);
      }
    },
    [namespace, publishName, service]
  );

  const getViewRowsMap = useCallback(
    async (viewId: string, rowIds: string[]) => {
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
