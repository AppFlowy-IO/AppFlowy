import { CollabType, YDoc, YjsEditorKey, YSharedRoot } from '@/application/collab.type';
import { applyYDoc } from '@/application/ydoc/apply';
import { getCollabDBName, openCollabDB } from './db';
import { Fetcher, StrategyType } from './types';

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

export function hasCache(doc: YDoc, type: CollabType) {
  const data = doc.getMap(YjsEditorKey.data_section) as YSharedRoot;

  return data.has(collabSharedRootKeyMap[type] as string);
}

export async function getCollab(
  fetcher: Fetcher<{
    state: Uint8Array;
  }>,
  {
    collabId,
    collabType,
    uuid,
  }: {
    uuid?: string;
    collabId: string;
    collabType: CollabType;
  },
  strategy: StrategyType = StrategyType.CACHE_AND_NETWORK
) {
  const name = getCollabDBName(collabId, collabTypeToDBType(collabType), uuid);
  const collab = await openCollabDB(name);
  const exist = hasCache(collab, collabType);

  switch (strategy) {
    case StrategyType.CACHE_ONLY: {
      if (!exist) {
        throw new Error('No cache found');
      }

      return collab;
    }

    case StrategyType.CACHE_FIRST: {
      if (!exist) {
        await revalidateCollab(fetcher, collab);
      }

      return collab;
    }

    case StrategyType.CACHE_AND_NETWORK: {
      if (!exist) {
        await revalidateCollab(fetcher, collab);
      } else {
        void revalidateCollab(fetcher, collab);
      }

      return collab;
    }

    default: {
      await revalidateCollab(fetcher, collab);

      return collab;
    }
  }
}

async function revalidateCollab(
  fetcher: Fetcher<{
    state: Uint8Array;
  }>,
  collab: YDoc
) {
  const { state } = await fetcher();

  applyYDoc(collab, state);
}

export async function batchCollab(
  batchFetcher: Fetcher<Record<string, number[]>>,
  collabs: {
    collabId: string;
    collabType: CollabType;
    uuid?: string;
  }[],
  strategy: StrategyType = StrategyType.CACHE_AND_NETWORK,
  itemCallback?: (id: string, doc: YDoc) => void
) {
  const collabMap = new Map<string, YDoc>();

  for (const { collabId, collabType, uuid } of collabs) {
    const name = getCollabDBName(collabId, collabTypeToDBType(collabType), uuid);
    const collab = await openCollabDB(name);
    const exist = hasCache(collab, collabType);

    collabMap.set(collabId, collab);
    if (exist) {
      itemCallback?.(collabId, collab);
    }
  }

  const notCacheIds = collabs.filter(({ collabId, collabType }) => {
    const id = collabMap.get(collabId);

    if (!id) return false;

    return !hasCache(id, collabType);
  });

  if (strategy === StrategyType.CACHE_ONLY) {
    if (notCacheIds.length > 0) {
      throw new Error('No cache found');
    }

    return;
  }

  if (strategy === StrategyType.CACHE_FIRST && notCacheIds.length === 0) {
    return;
  }

  const states = await batchFetcher();

  for (const [collabId, data] of Object.entries(states)) {
    const info = collabs.find((item) => item.collabId === collabId);
    const collab = collabMap.get(collabId);

    if (!info || !collab) {
      continue;
    }

    const state = new Uint8Array(data);

    applyYDoc(collab, state);

    itemCallback?.(collabId, collab);
  }
}
