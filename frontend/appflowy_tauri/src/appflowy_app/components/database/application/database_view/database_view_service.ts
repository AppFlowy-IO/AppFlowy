import {
  CreateViewPayloadPB,
  RepeatedViewIdPB,
  UpdateViewPayloadPB,
  ViewIdPB,
  ViewLayoutPB,
} from '@/services/backend';
import {
  FolderEventCreateView,
  FolderEventDeleteView,
  FolderEventReadView,
  FolderEventUpdateView,
} from '@/services/backend/events/flowy-folder2';
import { databaseService } from '../database';
import { DatabaseView, DatabaseViewLayout, pbToDatabaseView } from './database_view_types';

export async function getDatabaseViews(viewId: string): Promise<DatabaseView[]> {
  const payload = ViewIdPB.fromObject({ value: viewId });

  const result = await FolderEventReadView(payload);

  return result.map(value => {
    return [
      pbToDatabaseView(value),
      ...value.child_views.map(pbToDatabaseView),
    ];
  }).unwrap();
}

export async function createDatabaseView(
  viewId: string,
  layout: DatabaseViewLayout,
  name: string,
  databaseId?: string,
): Promise<DatabaseView> {
  const payload = CreateViewPayloadPB.fromObject({
    parent_view_id: viewId,
    name,
    layout,
    meta: {
      'database_id': databaseId || await databaseService.getDatabaseId(viewId),
    },
  });

  const result = await FolderEventCreateView(payload);

  return result.map(pbToDatabaseView).unwrap();
}

export async function updateView(viewId: string, view: { name?: string; layout?: ViewLayoutPB }): Promise<DatabaseView> {
  const payload = UpdateViewPayloadPB.fromObject({
    view_id: viewId,
    name: view.name,
    layout: view.layout,
  });

  const result = await FolderEventUpdateView(payload);

  return result.map(pbToDatabaseView).unwrap();
}

export async function deleteView(viewId: string): Promise<void> {
  const payload = RepeatedViewIdPB.fromObject({
    items: [viewId],
  });

  const result = await FolderEventDeleteView(payload);

  return result.unwrap();
}
