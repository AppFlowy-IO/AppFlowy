import {
  FolderEventCreateWorkspace,
  CreateWorkspacePayloadPB,
  FolderEventDeleteWorkspace,
  WorkspaceIdPB,
  FolderEventReadWorkspaceViews,
  FolderEventReadCurrentWorkspace,
} from '@/services/backend/events/flowy-folder2';
import { UserEventOpenWorkspace, UserWorkspaceIdPB } from '@/services/backend/events/flowy-user';

export class WorkspaceBackendService {
  constructor() {
    //
  }

  createWorkspace = async (params: ReturnType<typeof CreateWorkspacePayloadPB.prototype.toObject>) => {
    const { name, desc } = params;
    const payload = CreateWorkspacePayloadPB.fromObject({
      name,
      desc,
    });

    return FolderEventCreateWorkspace(payload);
  };

  openWorkspace = async (workspaceId: string) => {
    const payload = new UserWorkspaceIdPB({
      workspace_id: workspaceId,
    });

    return UserEventOpenWorkspace(payload);
  };

  deleteWorkspace = async (workspaceId: string) => {
    const payload = new WorkspaceIdPB({
      value: workspaceId,
    });

    return FolderEventDeleteWorkspace(payload);
  };

  getWorkspaces = async () => {
    return FolderEventReadCurrentWorkspace();
  };

  getCurrentWorkspace = async () => {
    return FolderEventReadCurrentWorkspace();
  };

  getChildPages = async (workspaceId: string) => {
    const payload = new WorkspaceIdPB({
      value: workspaceId,
    });

    return FolderEventReadWorkspaceViews(payload);
  };
}
