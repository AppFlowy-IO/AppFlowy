import {
  FolderEventCreateView,
  FolderEventUpdateView,
  FolderEventDeleteView,
  FolderEventDuplicateView,
  FolderEventCloseView,
  FolderEventImportData,
  ViewIdPB,
  CreateViewPayloadPB,
  UpdateViewPayloadPB,
  RepeatedViewIdPB,
  ViewPB,
  ImportPB,
  MoveNestedViewPayloadPB,
  FolderEventMoveNestedView,
  ViewIconPB,
  UpdateViewIconPayloadPB,
  FolderEventUpdateViewIcon,
  FolderEventCreateOrphanView,
  CreateOrphanViewPayloadPB,
  FolderEventGetView,
} from '@/services/backend/events/flowy-folder2';
import { Page, PageIcon } from '$app_reducers/pages/slice';

export class PageBackendService {
  constructor() {
    //
  }

  getPage = async (viewId: string) => {
    const payload = new ViewIdPB({
      value: viewId,
    });

    return FolderEventGetView(payload);
  };

  movePage = async (params: { viewId: string; parentId: string; prevId?: string }) => {
    const payload = new MoveNestedViewPayloadPB({
      view_id: params.viewId,
      new_parent_id: params.parentId,
      prev_view_id: params.prevId,
    });

    return FolderEventMoveNestedView(payload);
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

    return FolderEventUpdateView(payload);
  };

  updatePageIcon = async (viewId: string, icon?: PageIcon) => {
    const payload = new UpdateViewIconPayloadPB({
      view_id: viewId,
      icon: icon
        ? new ViewIconPB({
            ty: icon.ty,
            value: icon.value,
          })
        : undefined,
    });

    return FolderEventUpdateViewIcon(payload);
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

  createOrphanPage = async (params: ReturnType<typeof CreateOrphanViewPayloadPB.prototype.toObject>) => {
    const payload = CreateOrphanViewPayloadPB.fromObject(params);

    return FolderEventCreateOrphanView(payload);
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
