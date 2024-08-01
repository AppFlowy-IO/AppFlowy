import { APIService } from '@/application/services/js-services/http';

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

export function fetchPublishView(namespace: string, publishName: string) {
  const fetchFunction = () => APIService.getPublishView(namespace, publishName);

  return fetchWithDeduplication(`fetchPublishView_${namespace}`, { publishName }, fetchFunction);
}

export function fetchViewInfo(viewId: string) {
  const fetchFunction = () => APIService.getPublishInfoWithViewId(viewId);

  return fetchWithDeduplication(`fetchViewInfo`, { viewId }, fetchFunction);
}

export function fetchPublishViewMeta(namespace: string, publishName: string) {
  const fetchFunction = () => APIService.getPublishViewMeta(namespace, publishName);

  return fetchWithDeduplication(`fetchPublishViewMeta_${namespace}`, { publishName }, fetchFunction);
}
