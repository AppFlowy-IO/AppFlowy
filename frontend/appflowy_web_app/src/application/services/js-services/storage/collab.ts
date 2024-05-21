import { CollabType, YDoc, YjsEditorKey } from '@/application/collab.type';
import { getDBName, openCollabDB } from '@/application/services/js-services/db';
import { APIService } from '@/application/services/js-services/wasm';
import { applyDocument } from '@/application/ydoc/apply';

export function fetchCollab(workspaceId: string, id: string, type: CollabType) {
  return APIService.getCollab(workspaceId, id, type);
}

export function batchFetchCollab(workspaceId: string, params: { object_id: string; collab_type: CollabType }[]) {
  return APIService.batchGetCollab(workspaceId, params);
}

function collabTypeToDBType(type: CollabType) {
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

export async function getCollabStorage(id: string, type: CollabType) {
  const name = getDBName(id, collabTypeToDBType(type));

  const doc = await openCollabDB(name);
  const localExist = doc.share.has(YjsEditorKey.data_section);

  return {
    doc,
    localExist,
  };
}

export async function getCollabStorageWithAPICall(workspaceId: string, id: string, type: CollabType) {
  const { doc, localExist } = await getCollabStorage(id, type);
  const asyncApply = async () => {
    const res = await fetchCollab(workspaceId, id, type);

    applyDocument(doc, res.state);
  };

  // If the document exists locally, apply the state asynchronously,
  // otherwise, apply the state synchronously
  if (localExist) {
    void asyncApply();
  } else {
    await asyncApply();
  }

  return doc;
}

export async function batchCollabs(
  workspaceId: string,
  params: {
    object_id: string;
    collab_type: CollabType;
  }[],
  rowCallback?: (id: string, doc: YDoc) => void
) {
  console.log('Fetching collab data:', params);
  // Create or get Y.Doc from local storage
  for (const item of params) {
    const { object_id, collab_type } = item;

    const { doc } = await getCollabStorage(object_id, collab_type);

    if (rowCallback) {
      rowCallback(object_id, doc);
    }
  }

  // Async fetch collab data and apply to Y.Doc
  void (async () => {
    const res = await batchFetchCollab(workspaceId, params);

    for (const id of Object.keys(res)) {
      const type = params.find((param) => param.object_id === id)?.collab_type;
      const data = res[id];

      if (type === undefined || !data) {
        continue;
      }

      const { doc } = await getCollabStorage(id, type);

      applyDocument(doc, data);
    }
  })();
}
