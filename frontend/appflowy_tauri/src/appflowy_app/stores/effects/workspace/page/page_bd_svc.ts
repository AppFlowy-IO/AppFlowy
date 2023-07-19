import {
  FolderEventReadView,
  FolderEventCreateView,
  FolderEventUpdateView,
  FolderEventDeleteView,
  FolderEventDuplicateView,
  FolderEventCloseView,
  FolderEventImportData,
  FolderEventMoveView,
  ViewIdPB,
  CreateViewPayloadPB,
  UpdateViewPayloadPB,
  RepeatedViewIdPB,
  ViewPB,
  ImportPB,
  MoveViewPayloadPB,
} from '@/services/backend/events/flowy-folder2';
import { Page } from '$app_reducers/pages/slice';

export class PageBackendService {
  constructor() {
    //
  }

  getPage = async (viewId: string) => {
    const payload = new ViewIdPB({
      value: viewId,
    });

    return FolderEventReadView(payload);
  };

  movePage = async (params: { viewId: string; parentId: string; prevId?: string }) => {
    console.log('movePage', params);
    const payload = new MoveViewPayloadPB({
      view_id: params.viewId,
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      parent_view_id: params.parentId,
      prev_view_id: params.prevId,
    });

    return FolderEventMoveView(payload);
  };

  createPage = async (params: ReturnType<typeof CreateViewPayloadPB.prototype.toObject>) => {
    const payload = CreateViewPayloadPB.fromObject(params);

    return FolderEventCreateView(payload);
  };

  updatePage = async (page: { id: string } & Partial<Page>) => {
    const payload = new UpdateViewPayloadPB();

    payload.view_id = page.id;
    if (page.name !== undefined) {
      payload.name = page.name;
    }

    if (page.cover !== undefined) {
      payload.cover_url = page.cover;
    }

    if (page.icon !== undefined) {
      payload.icon_url = page.icon;
    }

    return FolderEventUpdateView(payload);
  };

  deletePage = async (viewId: string) => {
    const payload = new RepeatedViewIdPB({
      items: [viewId],
    });

    return FolderEventDeleteView(payload);
  };

  duplicatePage = async (params: ReturnType<typeof ViewPB.prototype.toObject>) => {
    const payload = ViewPB.fromObject(params);

    return FolderEventDuplicateView(payload);
  };

  closePage = async (viewId: string) => {
    const payload = new ViewIdPB({
      value: viewId,
    });

    return FolderEventCloseView(payload);
  };

  importData = async (params: ReturnType<typeof ImportPB.prototype.toObject>) => {
    const payload = ImportPB.fromObject(params);

    return FolderEventImportData(payload);
  };
}
