import { WorkspaceBackendService } from '$app/stores/effects/workspace/workspace_bd_svc';
import { WorkspaceObserver } from '$app/stores/effects/workspace/workspace_observer';
import { CreateViewPayloadPB } from '@/services/backend';
import { WorkspaceItem } from '$app_reducers/workspace/slice';
import { PageBackendService } from '$app/stores/effects/workspace/page/page_bd_svc';
import { Page, parserViewPBToPage } from '$app_reducers/pages/slice';
import { AsyncQueue } from '$app/utils/async_queue';

export class WorkspaceController {
  private readonly observer: WorkspaceObserver = new WorkspaceObserver();
  private readonly pageBackendService: PageBackendService;
  private readonly backendService: WorkspaceBackendService;
  private onWorkspaceChanged?: (data: WorkspaceItem) => void;
  private onWorkspaceDeleted?: () => void;
  private onChangeQueue?: AsyncQueue;
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
    onWorkspaceChanged?: (data: WorkspaceItem) => void;
    onWorkspaceDeleted?: () => void;
    onChildPagesChanged?: (childPages: Page[]) => void;
  }) => {
    this.onWorkspaceChanged = callbacks.onWorkspaceChanged;
    this.onWorkspaceDeleted = callbacks.onWorkspaceDeleted;
    const onChildPagesChanged = async () => {
      const childPages = await this.getChildPages();

      callbacks.onChildPagesChanged?.(childPages);
    };

    this.onChangeQueue = new AsyncQueue(onChildPagesChanged);
    await this.observer.subscribeWorkspace(this.workspaceId, {
      didUpdateWorkspace: this.didUpdateWorkspace,
      didDeleteWorkspace: this.didDeleteWorkspace,
      didUpdateChildViews: this.didUpdateChildPages,
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

  private didUpdateWorkspace = (payload: Uint8Array) => {
    // this.onWorkspaceChanged?.(payload.toObject());
  };

  private didDeleteWorkspace = (payload: Uint8Array) => {
    this.onWorkspaceDeleted?.();
  };

  private didUpdateChildPages = (payload: Uint8Array) => {
    this.onChangeQueue?.enqueue(Math.random());
  };
}
