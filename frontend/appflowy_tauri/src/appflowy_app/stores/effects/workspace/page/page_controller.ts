import { ViewLayoutPB } from '@/services/backend';
import { PageBackendService } from '$app/stores/effects/workspace/page/page_bd_svc';
import { WorkspaceObserver } from '$app/stores/effects/workspace/workspace_observer';
import { Page, parserViewPBToPage } from '$app_reducers/pages/slice';
import { AsyncQueue } from '$app/utils/async_queue';

export class PageController {
  private readonly backendService: PageBackendService = new PageBackendService();

  private readonly observer: WorkspaceObserver = new WorkspaceObserver();
  private onChangeQueue?: AsyncQueue;
  constructor(private readonly id: string) {
    //
  }

  dispose = () => {
    this.observer.unsubscribe();
  };

  createPage = async (params: { name: string; layout: ViewLayoutPB }): Promise<string> => {
    const result = await this.backendService.createPage({
      name: params.name,
      layout: params.layout,
      parent_view_id: this.id,
    });

    if (result.ok) {
      return result.val.id;
    }

    return Promise.reject(result.err);
  };

  movePage = async (params: { parentId: string; prevId?: string }): Promise<void> => {
    const result = await this.backendService.movePage({
      viewId: this.id,
      parentId: params.parentId,
      prevId: params.prevId,
    });

    if (result.ok) {
      return result.val;
    }

    return Promise.reject(result.err);
  };

  getChildPages = async (): Promise<Page[]> => {
    const result = await this.backendService.getPage(this.id);

    if (result.ok) {
      return result.val.child_views.map(parserViewPBToPage);
    }

    return [];
  };

  getPage = async (id?: string): Promise<Page> => {
    const result = await this.backendService.getPage(id || this.id);

    if (result.ok) {
      return parserViewPBToPage(result.val);
    }

    return Promise.reject(result.err);
  };

  getParentPage = async (): Promise<Page> => {
    const page = await this.getPage();
    const parentPageId = page.parentId;

    return this.getPage(parentPageId);
  };

  subscribe = async (callbacks: {
    onChildPagesChanged?: (childPages: Page[]) => void;
    onPageChanged?: (page: Page) => void;
  }) => {
    const onChanged = async () => {
      const page = await this.getPage();
      const childPages = await this.getChildPages();

      callbacks.onPageChanged?.(page);
      callbacks.onChildPagesChanged?.(childPages);
    };

    this.onChangeQueue = new AsyncQueue(onChanged);
    await this.observer.subscribeView(this.id, {
      didUpdateChildViews: this.didUpdateChildPages,
      didUpdateView: this.didUpdateView,
    });
  };

  unsubscribe = async () => {
    await this.observer.unsubscribe();
  };

  updatePage = async (page: { id: string } & Partial<Page>) => {
    const result = await this.backendService.updatePage(page);

    if (result.ok) {
      return result.val.toObject();
    }

    return Promise.reject(result.err);
  };

  deletePage = async () => {
    const result = await this.backendService.deletePage(this.id);

    if (result.ok) {
      return result.val;
    }

    return Promise.reject(result.err);
  };

  duplicatePage = async () => {
    const page = await this.getPage();
    const result = await this.backendService.duplicatePage(page);

    if (result.ok) {
      return result.val;
    }

    return Promise.reject(result.err);
  };

  private didUpdateChildPages = (payload: Uint8Array) => {
    this.onChangeQueue?.enqueue(Math.random());
  };

  private didUpdateView = (payload: Uint8Array) => {
    this.onChangeQueue?.enqueue(Math.random());
  };
}
