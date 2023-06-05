import { Err, Ok } from 'ts-results';
import {
  FolderEventCreateView,
  FolderEventMoveView,
  FolderEventReadWorkspaceViews,
  FolderEventReadAllWorkspaces,
} from '@/services/backend/events/flowy-folder2';
import { CreateViewPayloadPB, FlowyError, MoveViewPayloadPB, ViewLayoutPB, WorkspaceIdPB } from '@/services/backend';
import assert from 'assert';

export class WorkspaceBackendService {
  constructor(public readonly workspaceId: string) {}

  createApp = async (params: { name: string; desc?: string }) => {
    const payload = CreateViewPayloadPB.fromObject({
      parent_view_id: this.workspaceId,
      name: params.name,
      desc: params.desc || '',
      layout: ViewLayoutPB.Document,
    });

    const result = await FolderEventCreateView(payload);
    if (result.ok) {
      return result.val;
    } else {
      throw new Error(result.val.msg);
    }
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

  getApps = () => {
    const payload = WorkspaceIdPB.fromObject({ value: this.workspaceId });
    return FolderEventReadWorkspaceViews(payload).then((result) => result.map((val) => val.items));
  };

  moveApp = (params: { appId: string; fromIndex: number; toIndex: number }) => {
    const payload = MoveViewPayloadPB.fromObject({
      view_id: params.appId,
      from: params.fromIndex,
      to: params.toIndex,
    });
    return FolderEventMoveView(payload);
  };
}
