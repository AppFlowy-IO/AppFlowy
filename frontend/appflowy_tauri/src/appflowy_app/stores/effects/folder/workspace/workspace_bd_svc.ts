import { Err, Ok } from 'ts-results';
import {
  FolderEventCreateApp,
  FolderEventMoveItem,
  FolderEventReadWorkspaceApps,
  FolderEventReadWorkspaces,
} from '@/services/backend/events/flowy-folder';
import { CreateAppPayloadPB, WorkspaceIdPB, FlowyError, MoveFolderItemPayloadPB } from '@/services/backend';
import assert from 'assert';

export class WorkspaceBackendService {
  constructor(public readonly workspaceId: string) {}

  createApp = async (params: { name: string; desc?: string }) => {
    const payload = CreateAppPayloadPB.fromObject({
      workspace_id: this.workspaceId,
      name: params.name,
      desc: params.desc || '',
    });

    const result = await FolderEventCreateApp(payload);
    if (result.ok) {
      return result.val;
    } else {
      throw new Error(result.val.msg);
    }
  };

  getWorkspace = () => {
    const payload = WorkspaceIdPB.fromObject({ value: this.workspaceId });
    return FolderEventReadWorkspaces(payload).then((result) => {
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
    return FolderEventReadWorkspaceApps(payload).then((result) => result.map((val) => val.items));
  };

  moveApp = (params: { appId: string; fromIndex: number; toIndex: number }) => {
    const payload = MoveFolderItemPayloadPB.fromObject({
      item_id: params.appId,
      from: params.fromIndex,
      to: params.toIndex,
    });
    return FolderEventMoveItem(payload);
  };
}
