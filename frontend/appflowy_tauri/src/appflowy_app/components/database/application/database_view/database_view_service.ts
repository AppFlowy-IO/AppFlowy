import { CreateViewPayloadPB, RepeatedViewIdPB, UpdateViewPayloadPB, ViewIdPB, ViewLayoutPB } from '@/services/backend';
import {
  FolderEventCreateView,
  FolderEventDeleteView,
  FolderEventGetView,
  FolderEventUpdateView,
} from '@/services/backend/events/flowy-folder';
import { databaseService } from '../database';
import { Page, parserViewPBToPage } from '$app_reducers/pages/slice';

export async function getDatabaseViews(viewId: string): Promise<Page[]> {
  const payload = ViewIdPB.fromObject({ value: viewId });

  const result = await FolderEventGetView(payload);

  if (result.ok) {
    return [parserViewPBToPage(result.val), ...result.val.child_views.map(parserViewPBToPage)];
  }

  return Promise.reject(result.val);
}

export async function createDatabaseView(
  viewId: string,
  layout: ViewLayoutPB,
  name: string,
  databaseId?: string
): Promise<Page> {
  const payload = CreateViewPayloadPB.fromObject({
    parent_view_id: viewId,
    name,
    layout,
    meta: {
      database_id: databaseId || (await databaseService.getDatabaseId(viewId)),
    },
  });

  const result = await FolderEventCreateView(payload);

  if (result.ok) {
    return parserViewPBToPage(result.val);
  }

  return Promise.reject(result.err);
}

export async function updateView(viewId: string, view: { name?: string; layout?: ViewLayoutPB }): Promise<Page> {
  const payload = UpdateViewPayloadPB.fromObject({
    view_id: viewId,
    name: view.name,
    layout: view.layout,
  });

  const result = await FolderEventUpdateView(payload);

  if (result.ok) {
    return parserViewPBToPage(result.val);
  }

  return Promise.reject(result.err);
}

export async function deleteView(viewId: string): Promise<void> {
  const payload = RepeatedViewIdPB.fromObject({
    items: [viewId],
  });

  const result = await FolderEventDeleteView(payload);

  if (result.ok) {
    return;
  }

  return Promise.reject(result.err);
}
