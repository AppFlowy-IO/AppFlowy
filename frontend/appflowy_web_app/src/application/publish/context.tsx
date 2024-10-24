import {
  AppendBreadcrumb,
  CreateRowDoc,
  LoadView,
  LoadViewMeta,
  View,
  ViewInfo,
} from '@/application/types';
import { db } from '@/application/db';
import { ViewMeta } from '@/application/db/tables/view_metas';
import { findAncestors, findView } from '@/components/_shared/outline/utils';
import { useService } from '@/components/main/app.hooks';
import { notify } from '@/components/_shared/notify';
import { useLiveQuery } from 'dexie-react-hooks';
import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';

export interface PublishContextType {
  namespace: string;
  publishName: string;
  isTemplate?: boolean;
  isTemplateThumb?: boolean;
  viewMeta?: ViewMeta;
  toView: (viewId: string, blockId?: string) => Promise<void>;
  loadViewMeta: LoadViewMeta;
  createRowDoc?: CreateRowDoc;
  loadView: LoadView;
  outline?: View[];
  appendBreadcrumb?: AppendBreadcrumb;
  breadcrumbs: View[];
  rendered?: boolean;
  onRendered?: () => void;
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
  const createdRowKeys = useRef<string[]>([]);
  const [rendered, setRendered] = useState(false);

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

  const originalCrumbs = useMemo(() => {
    if (!viewMeta || !outline) return [];
    const ancestors = findAncestors(outline, viewMeta?.view_id);

    if (ancestors) return ancestors;
    if (!viewMeta?.ancestor_views) return [];
    const parseToView = (ancestor: ViewInfo): View => {
      let extra = null;

      try {
        extra = ancestor.extra ? JSON.parse(ancestor.extra) : null;
      } catch (e) {
        // do nothing
      }

      return {
        view_id: ancestor.view_id,
        name: ancestor.name,
        icon: ancestor.icon,
        layout: ancestor.layout,
        extra,
        is_published: true,
        children: [],
        is_private: false,
      };
    };

    const currentView = parseToView(viewMeta);

    return viewMeta?.ancestor_views.slice(1).map(item => findView(outline, item.view_id) || parseToView(item)) || [currentView];
  }, [viewMeta, outline]);

  const [breadcrumbs, setBreadcrumbs] = useState<View[]>([]);

  useEffect(() => {
    setBreadcrumbs(originalCrumbs);
  }, [originalCrumbs]);

  const appendBreadcrumb = useCallback((view?: View) => {
    setBreadcrumbs((prev) => {
      if (!view) {
        return prev.slice(0, -1);
      }

      const index = prev.findIndex((v) => v.view_id === view.view_id);

      if (index === -1) {
        return [...prev, view];
      }

      const rest = prev.slice(0, index);

      return [...rest, view];
    });
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

  const service = useService();

  useEffect(() => {
    const rowKeys = createdRowKeys.current;

    createdRowKeys.current = [];

    if (!rowKeys.length) return;
    rowKeys.forEach((rowKey) => {
      try {
        service?.deleteRowDoc(rowKey);
      } catch (e) {
        console.error(e);
      }
    });

  }, [service, publishName]);
  const navigate = useNavigate();
  const toView = useCallback(
    async (viewId: string, blockId?: string) => {
      try {
        const res = await service?.getPublishInfo(viewId);

        if (!res) {
          throw new Error('View has not been published yet');
        }

        const { namespace: viewNamespace, publishName } = res;

        prevViewMeta.current = undefined;
        const searchParams = new URLSearchParams('');

        if (blockId) {
          searchParams.set('blockId', blockId);
        }

        if (isTemplate) {
          searchParams.set('template', 'true');
        }
        
        let url = `/${viewNamespace}/${publishName}`;

        if (searchParams.toString()) {
          url += `?${searchParams.toString()}`;
        }

        navigate(url, {
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
            is_private: false,
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

  const createRowDoc = useCallback(
    async (rowKey: string) => {
      try {
        const doc = await service?.createRowDoc(rowKey);

        if (!doc) {
          throw new Error('Failed to create row doc');
        }

        createdRowKeys.current.push(rowKey);
        return doc;
      } catch (e) {
        return Promise.reject(e);
      }
    },
    [service],
  );

  const loadView = useCallback(
    async (viewId: string, isSubDocument?: boolean) => {
      if (isSubDocument) {
        const data = await service?.getPublishRowDocument(viewId);

        if (!data) {
          return Promise.reject(new Error('View has not been published yet'));
        }

        return data;
      }

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

  const onRendered = useCallback(() => {
    setRendered(true);
  }, []);

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
        createRowDoc,
        loadViewMeta,
        toView,
        namespace,
        publishName,
        isTemplateThumb,
        outline,
        breadcrumbs,
        appendBreadcrumb,
        onRendered,
        rendered,
      }}
    >
      {children}
    </PublishContext.Provider>
  );
};

export function usePublishContext () {
  return useContext(PublishContext);
}
