import { closeCollabDB, db, openCollabDB } from '@/application/db';
import { Fetcher, StrategyType } from '@/application/services/js-services/cache/types';
import {
  DatabaseId,
  PublishViewMetaData,
  RowId,
  Types,
  User,
  ViewId,
  ViewInfo,
  YDoc,
  YjsEditorKey,
  YSharedRoot,
} from '@/application/types';
import { applyYDoc } from '@/application/ydoc/apply';

export function collabTypeToDBType (type: Types) {
  switch (type) {
    case Types.Folder:
      return 'folder';
    case Types.Document:
      return 'document';
    case Types.Database:
      return 'database';
    case Types.WorkspaceDatabase:
      return 'databases';
    case Types.DatabaseRow:
      return 'database_row';
    case Types.UserAwareness:
      return 'user_awareness';
    default:
      return '';
  }
}

const collabSharedRootKeyMap = {
  [Types.Folder]: YjsEditorKey.folder,
  [Types.Document]: YjsEditorKey.document,
  [Types.Database]: YjsEditorKey.database,
  [Types.WorkspaceDatabase]: YjsEditorKey.workspace_database,
  [Types.DatabaseRow]: YjsEditorKey.database_row,
  [Types.UserAwareness]: YjsEditorKey.user_awareness,
  [Types.Empty]: YjsEditorKey.empty,
};

export function hasCollabCache (doc: YDoc) {
  const data = doc.getMap(YjsEditorKey.data_section) as YSharedRoot;

  return Object.values(collabSharedRootKeyMap).some((key) => {
    return data.has(key);
  });
}

export async function hasViewMetaCache (name: string) {
  const data = await db.view_metas.get(name);

  return !!data;
}

export async function hasUserCache (userId: string) {
  const data = await db.users.get(userId);

  return !!data;
}

export async function getPublishViewMeta<
  T extends {
    view: ViewInfo;
    child_views: ViewInfo[];
    ancestor_views: ViewInfo[];
  }
> (
  fetcher: Fetcher<T>,
  {
    namespace,
    publishName,
  }: {
    namespace: string;
    publishName: string;
  },
  strategy: StrategyType = StrategyType.CACHE_AND_NETWORK,
) {
  const name = `${namespace}_${publishName}`;
  const exist = await hasViewMetaCache(name);
  const meta = await db.view_metas.get(name);

  switch (strategy) {
    case StrategyType.CACHE_ONLY: {
      if (!exist) {
        throw new Error('No cache found');
      }

      return meta;
    }

    case StrategyType.CACHE_FIRST: {
      if (!exist) {
        return revalidatePublishViewMeta(name, fetcher);
      }

      return meta;
    }

    case StrategyType.CACHE_AND_NETWORK: {
      if (!exist) {
        return revalidatePublishViewMeta(name, fetcher);
      } else {
        void revalidatePublishViewMeta(name, fetcher);
      }

      return meta;
    }

    default: {
      return revalidatePublishViewMeta(name, fetcher);
    }
  }
}

export async function getUser<
  T extends User
> (
  fetcher: Fetcher<T>,
  userId?: string,
  strategy: StrategyType = StrategyType.CACHE_AND_NETWORK,
) {
  const exist = userId && (await hasUserCache(userId));
  const data = await db.users.get(userId);

  switch (strategy) {
    case StrategyType.CACHE_ONLY: {
      if (!exist) {
        throw new Error('No cache found');
      }

      return data;
    }

    case StrategyType.CACHE_FIRST: {
      if (!exist) {
        return revalidateUser(fetcher);
      }

      return data;
    }

    case StrategyType.CACHE_AND_NETWORK: {
      if (!exist) {
        return revalidateUser(fetcher);
      } else {
        void revalidateUser(fetcher);
      }

      return data;
    }

    default: {
      return revalidateUser(fetcher);
    }
  }
}

export async function getPublishView<
  T extends {
    data: Uint8Array;
    rows?: Record<RowId, number[]>;
    visibleViewIds?: ViewId[];
    relations?: Record<DatabaseId, ViewId>;
    subDocuments?: Record<string, number[]>;
    meta: {
      view: ViewInfo;
      child_views: ViewInfo[];
      ancestor_views: ViewInfo[];
    };
  }
> (
  fetcher: Fetcher<T>,
  {
    namespace,
    publishName,
  }: {
    namespace: string;
    publishName: string;
  },
  strategy: StrategyType = StrategyType.CACHE_AND_NETWORK,
) {
  const name = `${namespace}_${publishName}`;

  const doc = await openCollabDB(name);

  const exist = (await hasViewMetaCache(name)) && hasCollabCache(doc);

  switch (strategy) {
    case StrategyType.CACHE_ONLY: {
      if (!exist) {
        throw new Error('No cache found');
      }

      break;
    }

    case StrategyType.CACHE_FIRST: {
      if (!exist) {
        await revalidatePublishView(name, fetcher, doc);
      }

      break;
    }

    case StrategyType.CACHE_AND_NETWORK: {
      if (!exist) {
        await revalidatePublishView(name, fetcher, doc);
      } else {
        void revalidatePublishView(name, fetcher, doc);
      }

      break;
    }

    default: {
      await revalidatePublishView(name, fetcher, doc);
      break;
    }
  }

  return { doc };
}

export async function getPageDoc<T extends {
  data: Uint8Array;
  rows?: Record<RowId, number[]>;
}> (fetcher: Fetcher<T>, name: string, strategy: StrategyType = StrategyType.CACHE_AND_NETWORK) {

  const doc = await openCollabDB(name);

  const exist = hasCollabCache(doc);

  switch (strategy) {
    case StrategyType.CACHE_ONLY: {
      if (!exist) {
        throw new Error('No cache found');
      }

      break;
    }

    case StrategyType.CACHE_FIRST: {
      if (!exist) {
        await revalidateView(fetcher, doc);
      }

      break;
    }

    case StrategyType.CACHE_AND_NETWORK: {
      if (!exist) {
        await revalidateView(fetcher, doc);
      } else {
        void revalidateView(fetcher, doc);
      }

      break;
    }

    default: {
      await revalidateView(fetcher, doc);
      break;
    }
  }

  return { doc };
}

async function updateRows (collab: YDoc, rows: Record<RowId, number[]>) {
  const bulkData = [];

  for (const [key, value] of Object.entries(rows)) {
    const rowKey = `${collab.guid}_rows_${key}`;
    const doc = await createRowDoc(rowKey);

    const dbRow = await db.rows.get(key);

    applyYDoc(doc, new Uint8Array(value));

    bulkData.push({
      row_id: key,
      version: (dbRow?.version || 0) + 1,
      row_key: rowKey,
    });
  }

  await db.rows.bulkPut(bulkData);
}

export async function revalidateView<
  T extends {
    data: Uint8Array;
    rows?: Record<RowId, number[]>;
  }> (fetcher: Fetcher<T>, collab: YDoc) {
  try {
    const { data, rows } = await fetcher();

    if (rows) {
      await updateRows(collab, rows);
    }

    applyYDoc(collab, data);
  } catch (e) {
    return Promise.reject(e);
  }

}

export async function revalidatePublishViewMeta<
  T extends {
    view: ViewInfo;
    child_views: ViewInfo[];
    ancestor_views: ViewInfo[];
  }
> (name: string, fetcher: Fetcher<T>) {
  const { view, child_views, ancestor_views } = await fetcher();

  const dbView = await db.view_metas.get(name);

  await db.view_metas.put(
    {
      publish_name: name,
      ...view,
      child_views: child_views,
      ancestor_views: ancestor_views,
      visible_view_ids: dbView?.visible_view_ids ?? [],
      database_relations: dbView?.database_relations ?? {},
    },
    name,
  );

  return db.view_metas.get(name);
}

export async function revalidatePublishView<
  T extends {
    data: Uint8Array;
    rows?: Record<RowId, number[]>;
    visibleViewIds?: ViewId[];
    relations?: Record<DatabaseId, ViewId>;
    subDocuments?: Record<string, number[]>;
    meta: PublishViewMetaData;
  }
> (name: string, fetcher: Fetcher<T>, collab: YDoc) {
  const { data, meta, rows, visibleViewIds = [], relations = {}, subDocuments } = await fetcher();

  await db.view_metas.put(
    {
      publish_name: name,
      ...meta.view,
      child_views: meta.child_views,
      ancestor_views: meta.ancestor_views,
      visible_view_ids: visibleViewIds,
      database_relations: relations,
    },
    name,
  );

  if (rows) {
    await updateRows(collab, rows);
  }

  if (subDocuments) {
    for (const [key, value] of Object.entries(subDocuments)) {
      const doc = await openCollabDB(key);

      applyYDoc(doc, new Uint8Array(value));
    }
  }

  applyYDoc(collab, data);
}

export async function deleteViewMeta (name: string) {
  try {
    await db.view_metas.delete(name);

  } catch (e) {
    console.error(e);
  }
}

export async function deleteView (name: string) {
  console.log('deleteView', name);
  await deleteViewMeta(name);
  await closeCollabDB(name);

  await closeCollabDB(`${name}_rows`);
}

export async function revalidateUser<
  T extends User> (fetcher: Fetcher<T>) {
  const data = await fetcher();

  await db.users.put(data, data.uuid);

  return data;
}

const rowDocs = new Map<string, YDoc>();

export async function createRowDoc (rowKey: string) {
  if (rowDocs.has(rowKey)) {
    return rowDocs.get(rowKey) as YDoc;
  }

  const doc = await openCollabDB(rowKey);

  rowDocs.set(rowKey, doc);

  return doc;
}

export function deleteRowDoc (rowKey: string) {
  rowDocs.delete(rowKey);
}
