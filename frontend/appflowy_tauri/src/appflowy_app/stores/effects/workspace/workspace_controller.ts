import { WorkspaceBackendService } from '$app/stores/effects/workspace/workspace_bd_svc';
import { WorkspaceObserver } from '$app/stores/effects/workspace/workspace_observer';
import { CreateViewPayloadPB, RepeatedViewPB } from "@/services/backend";
import { PageBackendService } from '$app/stores/effects/workspace/page/page_bd_svc';
import { Page, parserViewPBToPage } from '$app_reducers/pages/slice';

export class WorkspaceController {
  private readonly observer: WorkspaceObserver = new WorkspaceObserver();
  private readonly pageBackendService: PageBackendService;
  private readonly backendService: WorkspaceBackendService;
  constructor(private readonly workspaceId: string) {
    this.pageBackendService = new PageBackendService();
    this.backendService = new WorkspaceBackendService();
  }

  dispose = () => {
    this.observer.unsubscribe();
  };

  open = async () => {
    const result = await this.backendService.openWorkspace(this.workspaceId);

    if (result.ok) {
      return result.val;
    }

    return Promise.reject(result.err);
  };

  delete = async () => {
    const result = await this.backendService.deleteWorkspace(this.workspaceId);

    if (result.ok) {
      return result.val;
    }

    return Promise.reject(result.err);
  };

  subscribe = async (callbacks: {
    onChildPagesChanged?: (childPages: Page[]) => void;
  }) => {

    const didUpdateWorkspace = (payload: Uint8Array) => {
      const res = RepeatedViewPB.deserializeBinary(payload).items;
      callbacks.onChildPagesChanged?.(res.map(parserViewPBToPage));
    }
    await this.observer.subscribeWorkspace(this.workspaceId, {
      didUpdateWorkspace
    });
  };

  createView = async (params: ReturnType<typeof CreateViewPayloadPB.prototype.toObject>) => {
    const result = await this.pageBackendService.createPage(params);

    if (result.ok) {
      const view = result.val;

      return view;
    }

    return Promise.reject(result.err);
  };

  getChildPages = async (): Promise<Page[]> => {
    const result = await this.backendService.getChildPages(this.workspaceId);

    if (result.ok) {
      return result.val.items.map(parserViewPBToPage);
    }

    return [];
  };


}
