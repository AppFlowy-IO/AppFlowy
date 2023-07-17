import {
  FolderEventCreateWorkspace,
  FolderEventGetCurrentWorkspace,
  CreateWorkspacePayloadPB,
  FolderEventReadAllWorkspaces,
  FolderEventOpenWorkspace,
  FolderEventDeleteWorkspace,
  WorkspaceIdPB,
  FolderEventReadWorkspaceViews,
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
    // if workspaceId is not provided, it will return all workspaces
    const workspaceId = new WorkspaceIdPB();

    return FolderEventReadAllWorkspaces(workspaceId);
  };

  getCurrentWorkspace = async () => {
    return FolderEventGetCurrentWorkspace();
  };

  getChildPages = async (workspaceId: string) => {
    const payload = new WorkspaceIdPB({
      value: workspaceId,
    });

    return FolderEventReadWorkspaceViews(payload);
  };
}
