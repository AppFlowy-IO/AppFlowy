import { ViewLayoutPB, ViewPB } from '@/services/backend';
import { PageBackendService } from '$app/stores/effects/workspace/page/page_bd_svc';
import { WorkspaceObserver } from '$app/stores/effects/workspace/workspace_observer';
import { Page, PageIcon, parserViewPBToPage } from '$app_reducers/pages/slice';

export class PageController {
  private readonly backendService: PageBackendService = new PageBackendService();

  private readonly observer: WorkspaceObserver = new WorkspaceObserver();
  constructor(private readonly id: string) {
    //
  }

  dispose = async () => {
    await this.observer.unsubscribe();
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

  getPage = async (id?: string) => {
    const result = await this.backendService.getPage(id || this.id);

    if (result.ok) {
      return parserViewPBToPage(result.val);
    }

    return Promise.reject(result.val);
  };

  getParentPage = async (): Promise<Page> => {
    const page = await this.getPage();
    const parentPageId = page.parentId;

    return this.getPage(parentPageId);
  };

  subscribe = async (callbacks: { onPageChanged?: (page: Page, children: Page[]) => void }) => {
    const didUpdateView = (payload: Uint8Array) => {
      const res = ViewPB.deserializeBinary(payload);
      const page = parserViewPBToPage(res);

      const childPages = res.child_views.map(parserViewPBToPage);

      callbacks.onPageChanged?.(page, childPages);
    };

    await this.observer.subscribeView(this.id, {
      didUpdateView,
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

  updatePageIcon = async (icon?: PageIcon) => {
    const result = await this.backendService.updatePageIcon(this.id, icon);

    if (result.ok) {
      return result.val;
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

  createOrphanPage = async (params: { name: string; layout: ViewLayoutPB }): Promise<Page> => {
    const result = await this.backendService.createOrphanPage({
      view_id: this.id,
      name: params.name,
      layout: params.layout,
    });

    if (result.ok) {
      return parserViewPBToPage(result.val);
    }

    return Promise.reject(result.val);
  };
}
