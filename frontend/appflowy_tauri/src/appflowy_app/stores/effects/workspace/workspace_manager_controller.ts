import { WorkspaceBackendService } from './workspace_bd_svc';
import { CreateWorkspacePayloadPB, RepeatedWorkspacePB } from '@/services/backend';
import { WorkspaceItem } from '$app_reducers/workspace/slice';
import { WorkspaceObserver } from '$app/stores/effects/workspace/workspace_observer';

export class WorkspaceManagerController {
  private readonly observer: WorkspaceObserver;
  private readonly backendService: WorkspaceBackendService = new WorkspaceBackendService();
  private onWorkspacesChanged?: (data: { workspaces: WorkspaceItem[]; currentWorkspace: WorkspaceItem }) => void;

  constructor() {
    this.observer = new WorkspaceObserver();
  }

  subscribe = async (callbacks: {
    onWorkspacesChanged?: (data: { workspaces: WorkspaceItem[]; currentWorkspace: WorkspaceItem }) => void;
  }) => {
    // this.observer.subscribeWorkspaces(this.didCreateWorkspace);
    this.onWorkspacesChanged = callbacks.onWorkspacesChanged;
  };

  createWorkspace = async (params: ReturnType<typeof CreateWorkspacePayloadPB.prototype.toObject>) => {
    const result = await this.backendService.createWorkspace(params);

    if (result.ok) {
      return result.val;
    }

    return Promise.reject(result.err);
  };

  getWorkspaces = async (): Promise<WorkspaceItem[]> => {
    const result = await this.backendService.getWorkspaces();

    if (result.ok) {
      const item = result.val;

      return [
        {
          id: item.id,
          name: item.name,
        },
      ];
    }

    return [];
  };

  getCurrentWorkspace = async (): Promise<WorkspaceItem | null> => {
    const result = await this.backendService.getCurrentWorkspace();

    if (result.ok) {
      const workspace = result.val;
      return {
        id: workspace.id,
        name: workspace.name,
      };
    }

    return null;
  };

  dispose = async () => {
    await this.observer.unsubscribe();
  };

  private didCreateWorkspace = (payload: Uint8Array) => {
    const data = RepeatedWorkspacePB.deserializeBinary(payload);
    // onWorkspacesChanged(data.toObject().items);
  };
}
