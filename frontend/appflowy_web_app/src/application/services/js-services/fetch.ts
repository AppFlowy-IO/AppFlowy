import { CollabType } from '@/application/collab.type';
import { APIService } from '@/application/services/js-services/wasm';

const pendingRequests = new Map();

function generateRequestKey<T>(url: string, params: T) {
  if (!params) return url;

  try {
    return `${url}_${JSON.stringify(params)}`;
  } catch (_e) {
    return `${url}_${params}`;
  }
}

// Deduplication fetch requests
// When multiple requests are made to the same URL with the same params, only one request is made
// and the result is shared with all the requests
function fetchWithDeduplication<Req, Res>(url: string, params: Req, fetchFunction: () => Promise<Res>): Promise<Res> {
  const requestKey = generateRequestKey<Req>(url, params);

  if (pendingRequests.has(requestKey)) {
    return pendingRequests.get(requestKey);
  }

  const fetchPromise = fetchFunction().finally(() => {
    pendingRequests.delete(requestKey);
  });

  pendingRequests.set(requestKey, fetchPromise);
  return fetchPromise;
}

/**
 * Fetch collab
 * @param workspaceId
 * @param id
 * @param type [CollabType]
 */
export function fetchCollab(workspaceId: string, id: string, type: CollabType) {
  const fetchFunction = () => APIService.getCollab(workspaceId, id, type);

  return fetchWithDeduplication(`fetchCollab_${workspaceId}`, { id, type }, fetchFunction);
}

/**
 * Batch fetch collab
 * Usage:
 *   // load database rows
 *   const rows = await batchFetchCollab(workspaceId, databaseRows.map((row) => ({ collabId: row.id, collabType: CollabType.DatabaseRow })));
 *
 * @param workspaceId
 * @param params [{ collabId: string; collabType: CollabType }]
 */
export function batchFetchCollab(workspaceId: string, params: { collabId: string; collabType: CollabType }[]) {
  const fetchFunction = () =>
    APIService.batchGetCollab(
      workspaceId,
      params.map(({ collabId, collabType }) => ({
        object_id: collabId,
        collab_type: collabType,
      }))
    );

  return fetchWithDeduplication(`batchFetchCollab_${workspaceId}`, params, fetchFunction);
}
