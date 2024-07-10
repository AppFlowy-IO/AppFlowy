import {
  CollabType,
  PublishViewInfo,
  PublishViewMetaData,
  YDoc,
  YjsEditorKey,
  YSharedRoot,
} from '@/application/collab.type';
import { applyYDoc } from '@/application/ydoc/apply';
import { closeCollabDB, db, openCollabDB } from '@/application/db';
import { Fetcher, StrategyType } from '@/application/services/js-services/cache/types';
import * as Y from 'yjs';

export function collabTypeToDBType(type: CollabType) {
  switch (type) {
    case CollabType.Folder:
      return 'folder';
    case CollabType.Document:
      return 'document';
    case CollabType.Database:
      return 'database';
    case CollabType.WorkspaceDatabase:
      return 'databases';
    case CollabType.DatabaseRow:
      return 'database_row';
    case CollabType.UserAwareness:
      return 'user_awareness';
    default:
      return '';
  }
}

const collabSharedRootKeyMap = {
  [CollabType.Folder]: YjsEditorKey.folder,
  [CollabType.Document]: YjsEditorKey.document,
  [CollabType.Database]: YjsEditorKey.database,
  [CollabType.WorkspaceDatabase]: YjsEditorKey.workspace_database,
  [CollabType.DatabaseRow]: YjsEditorKey.database_row,
  [CollabType.UserAwareness]: YjsEditorKey.user_awareness,
  [CollabType.Empty]: YjsEditorKey.empty,
};

export function hasCollabCache(doc: YDoc) {
  const data = doc.getMap(YjsEditorKey.data_section) as YSharedRoot;

  return Object.values(collabSharedRootKeyMap).some((key) => {
    return data.has(key);
  });
}

export async function hasViewMetaCache(name: string) {
  const data = await db.view_metas.get(name);

  return !!data;
}

export async function getPublishViewMeta<
  T extends {
    view: PublishViewInfo;
    child_views: PublishViewInfo[];
    ancestor_views: PublishViewInfo[];
  }
>(
  fetcher: Fetcher<T>,
  {
    namespace,
    publishName,
  }: {
    namespace: string;
    publishName: string;
  },
  strategy: StrategyType = StrategyType.CACHE_AND_NETWORK
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

export async function getPublishView<
  T extends {
    data: number[];
    rows?: Record<string, number[]>;
    visibleViewIds?: string[];
    meta: {
      view: PublishViewInfo;
      child_views: PublishViewInfo[];
      ancestor_views: PublishViewInfo[];
    };
  }
>(
  fetcher: Fetcher<T>,
  {
    namespace,
    publishName,
  }: {
    namespace: string;
    publishName: string;
  },
  strategy: StrategyType = StrategyType.CACHE_AND_NETWORK
) {
  const name = `${namespace}_${publishName}`;
  const doc = await openCollabDB(name);
  const rowMapDoc = await openCollabDB(`${name}_rows`);

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

export async function revalidatePublishViewMeta<
  T extends {
    view: PublishViewInfo;
    child_views: PublishViewInfo[];
    ancestor_views: PublishViewInfo[];
  }
>(name: string, fetcher: Fetcher<T>) {
  const { view, child_views, ancestor_views } = await fetcher();

  const dbView = await db.view_metas.get(name);

  await db.view_metas.put(
    {
      publish_name: name,
      ...view,
      child_views: child_views,
      ancestor_views: ancestor_views,
      visible_view_ids: dbView?.visible_view_ids ?? [],
    },
    name
  );

  return db.view_metas.get(name);
}

export async function revalidatePublishView<
  T extends {
    data: number[];
    rows?: Record<string, number[]>;
    visibleViewIds?: string[];
    meta: PublishViewMetaData;
  }
>(name: string, fetcher: Fetcher<T>, collab: YDoc, rowMapDoc: Y.Doc) {
  const { data, meta, rows, visibleViewIds = [] } = await fetcher();

  await db.view_metas.put(
    {
      publish_name: name,
      ...meta.view,
      child_views: meta.child_views,
      ancestor_views: meta.ancestor_views,
      visible_view_ids: visibleViewIds,
    },
    name
  );

  if (rows) {
    for (const [key, value] of Object.entries(rows)) {
      if (!rowMapDoc.getMap().has(key)) {
        const row = new Y.Doc({
          guid: key,
        });

        rowMapDoc.getMap().set(key, row);
      }

      const row = rowMapDoc.getMap().get(key) as YDoc;

      applyYDoc(row, new Uint8Array(value));

      rowMapDoc.getMap().delete(key);
      rowMapDoc.getMap().set(key, row);
    }
  }

  const state = new Uint8Array(data);

  applyYDoc(collab, state);
}

export async function deleteViewMeta(name: string) {
  await db.view_metas.delete(name);
}

export async function deleteView(name: string) {
  console.log('deleteView', name);
  await deleteViewMeta(name);
  await closeCollabDB(name);
  await closeCollabDB(`${name}_rows`);
}
