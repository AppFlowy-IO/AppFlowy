import {
  Types,
  DatabaseId,
  ViewInfo,
  PublishViewMetaData,
  RowId,
  ViewId,
  YDoc,
  YjsEditorKey,
  YSharedRoot,
  User,
} from '@/application/types';
import { applyYDoc } from '@/application/ydoc/apply';
import { closeCollabDB, db, openCollabDB } from '@/application/db';
import { Fetcher, StrategyType } from '@/application/services/js-services/cache/types';
// import { IndexeddbPersistence } from 'y-indexeddb';
import * as Y from 'yjs';

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
  const rowMapDoc = (await openCollabDB(`${name}_rows`)) as Y.Doc;

  // const subdocs = Array.from(rowMapDoc.getSubdocs());
  //
  // for (const subdoc of subdocs) {
  //   const promise = new Promise((resolve) => {
  //     const persistence = new IndexeddbPersistence(subdoc.guid, subdoc);
  //
  //     persistence.on('synced', () => {
  //       resolve(true);
  //     });
  //   });
  //
  //   await promise;
  // }

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
        await revalidatePublishView(name, fetcher, doc, rowMapDoc);
      }

      break;
    }

    case StrategyType.CACHE_AND_NETWORK: {
      if (!exist) {
        await revalidatePublishView(name, fetcher, doc, rowMapDoc);
      } else {
        void revalidatePublishView(name, fetcher, doc, rowMapDoc);
      }

      break;
    }

    default: {
      await revalidatePublishView(name, fetcher, doc, rowMapDoc);
      break;
    }
  }

  return { doc, rowMapDoc };
}

export async function getPageDoc<T extends {
  data: Uint8Array;
  rows?: Record<RowId, number[]>;
}> (fetcher: Fetcher<T>, name: string, strategy: StrategyType = StrategyType.CACHE_AND_NETWORK) {

  const doc = await openCollabDB(name);
  const rowMapDoc = (await openCollabDB(`${name}_rows`)) as Y.Doc;

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
        await revalidateView(fetcher, doc, rowMapDoc);
      }

      break;
    }

    case StrategyType.CACHE_AND_NETWORK: {
      if (!exist) {
        await revalidateView(fetcher, doc, rowMapDoc);
      } else {
        void revalidateView(fetcher, doc, rowMapDoc);
      }

      break;
    }

    default: {
      await revalidateView(fetcher, doc, rowMapDoc);
      break;
    }
  }

  return { doc, rowMapDoc };
}

export async function revalidateView<
  T extends {
    data: Uint8Array;
    rows?: Record<RowId, number[]>;
  }> (fetcher: Fetcher<T>, collab: YDoc, rowMapDoc: Y.Doc) {
  const { data, rows } = await fetcher();

  if (rows) {
    for (const [key, value] of Object.entries(rows)) {
      const subdoc = new Y.Doc({
        guid: key,
      });

      applyYDoc(subdoc, new Uint8Array(value));
      rowMapDoc.getMap().delete(subdoc.guid);
      rowMapDoc.getMap().set(subdoc.guid, subdoc);
    }
  }

  console.log('revalidateView', collab, data);
  applyYDoc(collab, data);
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
    meta: PublishViewMetaData;
  }
> (name: string, fetcher: Fetcher<T>, collab: YDoc, rowMapDoc: Y.Doc) {
  const { data, meta, rows, visibleViewIds = [], relations = {} } = await fetcher();

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
    for (const [key, value] of Object.entries(rows)) {
      const subdoc = new Y.Doc({
        guid: key,
      });

      applyYDoc(subdoc, new Uint8Array(value));
      rowMapDoc.getMap().delete(subdoc.guid);
      rowMapDoc.getMap().set(subdoc.guid, subdoc);
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
  // const rowMapDoc = (await openCollabDB(`${name}_rows`)) as Y.Doc;
  //
  // const subdocs = Array.from(rowMapDoc.getSubdocs());
  //
  // for (const subdoc of subdocs) {
  //   const persistence = new IndexeddbPersistence(subdoc.guid, subdoc);
  //
  //   await persistence.destroy();
  // }

  await closeCollabDB(`${name}_rows`);
}

export async function revalidateUser<
  T extends User> (fetcher: Fetcher<T>) {
  const data = await fetcher();

  await db.users.put(data, data.uuid);

  return data;
}
