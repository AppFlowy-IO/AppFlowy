import {
  GetViewRowsMap,
  LoadView,
  LoadViewMeta,
  View,
  ViewInfo,
} from '@/application/types';
import { db } from '@/application/db';
import { ViewMeta } from '@/application/db/tables/view_metas';
import { findView } from '@/components/_shared/outline/utils';
import { useService } from '@/components/main/app.hooks';
import { notify } from '@/components/_shared/notify';
import { useLiveQuery } from 'dexie-react-hooks';
import { createContext, useCallback, useContext, useEffect, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';

export interface PublishContextType {
  namespace: string;
  publishName: string;
  isTemplate?: boolean;
  isTemplateThumb?: boolean;
  viewMeta?: ViewMeta;
  toView: (viewId: string) => Promise<void>;
  loadViewMeta: LoadViewMeta;
  getViewRowsMap?: GetViewRowsMap;
  loadView: LoadView;
  outline?: View[];
}

export const PublishContext = createContext<PublishContextType | null>(null);

export const PublishProvider = ({
  children,
  namespace,
  publishName,
  isTemplateThumb,
  isTemplate,
}: {
  children: React.ReactNode;
  namespace: string;
  publishName: string;
  isTemplateThumb?: boolean;
  isTemplate?: boolean;
}) => {

  const [outline, setOutline] = useState<View[]>([]);

  const [subscribers, setSubscribers] = useState<Map<string, (meta: ViewMeta) => void>>(new Map());

  useEffect(() => {
    return () => {
      setSubscribers(new Map());
    };
  }, []);

  const viewMeta = useLiveQuery(async () => {
    const name = `${namespace}_${publishName}`;

    const view = await db.view_metas.get(name);

    if (!view) return;

    return {
      ...view,
      name: findView(outline, view.view_id)?.name || view.name,
    };
  }, [namespace, publishName, outline]);

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

  const service = useService();

  const navigate = useNavigate();
  const toView = useCallback(
    async (viewId: string) => {
      try {
        const res = await service?.getPublishInfo(viewId);

        if (!res) {
          throw new Error('View has not been published yet');
        }

        const { namespace: viewNamespace, publishName } = res;

        prevViewMeta.current = undefined;
        navigate(`/${viewNamespace}/${publishName}${isTemplate ? '?template=true' : ''}`, {
          replace: true,
        });
        return;
      } catch (e) {
        return Promise.reject(e);
      }
    },
    [navigate, service, isTemplate],
  );

  const loadOutline = useCallback(async () => {
    if (!service || !namespace) return;
    try {
      const res = await service?.getPublishOutline(namespace);

      if (!res) {
        throw new Error('Publish outline not found');
      }

      setOutline(res);
    } catch (e) {
      notify.error('Publish outline not found');
    }
  }, [namespace, service]);

  const loadViewMeta = useCallback(
    async (viewId: string, callback?: (meta: View) => void) => {
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

        const parseMetaToView = (meta: ViewInfo | ViewMeta): View => {
          return {
            view_id: meta.view_id,
            name: meta.name,
            layout: meta.layout,
            extra: meta.extra ? JSON.parse(meta.extra) : undefined,
            icon: meta.icon,
            children: meta.child_views?.map(parseMetaToView) || [],
            is_published: true,
            database_relations: 'database_relations' in meta ? meta.database_relations : undefined,
          };
        };

        const res = parseMetaToView(meta);

        callback?.(res);

        if (callback) {
          setSubscribers((prev) => {
            prev.set(name, (meta) => {
              return callback?.(parseMetaToView(meta));
            });

            return prev;
          });
        }

        return res;
      } catch (e) {
        return Promise.reject(e);
      }
    },
    [service],
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
    [service],
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
    [service],
  );

  useEffect(() => {
    if (!viewMeta && prevViewMeta.current) {
      window.location.reload();
      return;
    }

    prevViewMeta.current = viewMeta;
  }, [viewMeta]);

  useEffect(() => {
    void loadOutline();
  }, [loadOutline]);

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
        isTemplateThumb,
        outline,
      }}
    >
      {children}
    </PublishContext.Provider>
  );
};

export function usePublishContext () {
  return useContext(PublishContext);
}
