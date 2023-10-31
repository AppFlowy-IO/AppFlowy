import {
  FolderEventCreateWorkspace,
  CreateWorkspacePayloadPB,
  FolderEventOpenWorkspace,
  FolderEventDeleteWorkspace,
  WorkspaceIdPB,
  FolderEventReadWorkspaceViews,
  FolderEventReadCurrentWorkspace,
} from '@/services/backend/events/flowy-folder2';

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
    const payload = new WorkspaceIdPB({
      value: workspaceId,
    });

    return FolderEventOpenWorkspace(payload);
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
