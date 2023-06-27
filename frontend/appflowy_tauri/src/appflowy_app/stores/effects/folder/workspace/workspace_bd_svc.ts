import { Err, Ok, Result } from 'ts-results';
import {
  FolderEventCreateView,
  FolderEventMoveView,
  FolderEventReadWorkspaceViews,
  FolderEventReadAllWorkspaces,
  ViewPB,
} from '@/services/backend/events/flowy-folder2';
import { CreateViewPayloadPB, FlowyError, MoveViewPayloadPB, ViewLayoutPB, WorkspaceIdPB } from '@/services/backend';
import assert from 'assert';

export class WorkspaceBackendService {
  constructor(public readonly workspaceId: string) {}

  createView = async (params: {
    name: string;
    desc?: string;
    layoutType: ViewLayoutPB;
    parentViewId?: string;
    /// The initial data should be the JSON of the document
    /// For example: {"document":{"type":"editor","children":[]}}
    initialData?: string;
  }) => {
    const encoder = new TextEncoder();
    const payload = CreateViewPayloadPB.fromObject({
      parent_view_id: params.parentViewId ?? this.workspaceId,
      name: params.name,
      desc: params.desc || '',
      layout: params.layoutType,
      initial_data: encoder.encode(params.initialData || ''),
    });

    return FolderEventCreateView(payload);
  };

  getWorkspace = () => {
    const payload = WorkspaceIdPB.fromObject({ value: this.workspaceId });
    return FolderEventReadAllWorkspaces(payload).then((result) => {
      if (result.ok) {
        const workspaces = result.val.items;
        if (workspaces.length === 0) {
          return Err(FlowyError.fromObject({ msg: 'workspace not found' }));
        } else {
          assert(workspaces.length === 1);
          return Ok(workspaces[0]);
        }
      } else {
        return Err(result.val);
      }
    });
  };

  getAllViews: () => Promise<Result<ViewPB[], FlowyError>> = async () => {
    const payload = WorkspaceIdPB.fromObject({ value: this.workspaceId });
    const result = await FolderEventReadWorkspaceViews(payload);
    if (result.ok) {
      return Ok(result.val.items);
    } else {
      return result;
    }
  };

  moveView = (params: { viewId: string; fromIndex: number; toIndex: number }) => {
    const payload = MoveViewPayloadPB.fromObject({
      view_id: params.viewId,
      from: params.fromIndex,
      to: params.toIndex,
    });
    return FolderEventMoveView(payload);
  };
}
