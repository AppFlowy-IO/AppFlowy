import { MetaData } from '@/application/db/tables/view_metas';
import { CollabType, YDoc, YjsEditorKey, YSharedRoot } from '@/application/collab.type';
import { applyYDoc } from '@/application/ydoc/apply';
import { db, openCollabDB } from '@/application/db';
import { Fetcher, StrategyType } from '@/application/services/js-services/cache/types';

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
    metadata: {
      view: MetaData;
      child_views: MetaData[];
      ancestor_views: MetaData[];
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
    meta: {
      metadata: {
        view: MetaData;
        child_views: MetaData[];
        ancestor_views: MetaData[];
      };
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

  return doc;
}

export async function revalidatePublishViewMeta<
  T extends {
    metadata: {
      view: MetaData;
      child_views: MetaData[];
      ancestor_views: MetaData[];
    };
  }
>(name: string, fetcher: Fetcher<T>) {
  const { metadata } = await fetcher();

  await db.view_metas.put(
    {
      publish_name: name,
      ...metadata.view,
      child_views: metadata.child_views,
      ancestor_views: metadata.ancestor_views,
    },
    name
  );
}

export async function revalidatePublishView<
  T extends {
    data: number[];
    rows?: Record<string, number[]>;
    meta: {
      metadata: {
        view: MetaData;
        child_views: MetaData[];
        ancestor_views: MetaData[];
      };
    };
  }
>(name: string, fetcher: Fetcher<T>, collab: YDoc) {
  const { data, meta, rows } = await fetcher();

  await db.view_metas.put(
    {
      publish_name: name,
      ...meta.metadata.view,
      child_views: meta.metadata.child_views,
      ancestor_views: meta.metadata.ancestor_views,
    },
    name
  );

  for (const [key, value] of Object.entries(rows ?? {})) {
    const row = await openCollabDB(`${name}_${key}`);

    applyYDoc(row, new Uint8Array(value));
  }

  const state = new Uint8Array(data);

  applyYDoc(collab, state);
}

export async function getBatchCollabs(names: string[]) {
  const collabs = await Promise.all(names.map((name) => openCollabDB(name)));

  return collabs;
}
