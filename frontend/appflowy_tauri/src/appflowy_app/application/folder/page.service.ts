import { Page, PageIcon, parserViewPBToPage } from '$app_reducers/pages/slice';
import {
  CreateOrphanViewPayloadPB,
  CreateViewPayloadPB,
  MoveNestedViewPayloadPB,
  RepeatedViewIdPB,
  UpdateViewIconPayloadPB,
  UpdateViewPayloadPB,
  ViewIconPB,
  ViewIdPB,
  ViewPB,
} from '@/services/backend';
import {
  FolderEventCreateOrphanView,
  FolderEventCreateView,
  FolderEventDeleteView,
  FolderEventDuplicateView,
  FolderEventGetView,
  FolderEventMoveNestedView,
  FolderEventUpdateView,
  FolderEventUpdateViewIcon,
  FolderEventSetLatestView,
} from '@/services/backend/events/flowy-folder';

export async function getPage(id: string) {
  const payload = new ViewIdPB({
    value: id,
  });

  const result = await FolderEventGetView(payload);

  if (result.ok) {
    return parserViewPBToPage(result.val);
  }

  return Promise.reject(result.val);
}

export const createOrphanPage = async (
  params: ReturnType<typeof CreateOrphanViewPayloadPB.prototype.toObject>
): Promise<Page> => {
  const payload = CreateOrphanViewPayloadPB.fromObject(params);

  const result = await FolderEventCreateOrphanView(payload);

  if (result.ok) {
    return parserViewPBToPage(result.val);
  }

  return Promise.reject(result.val);
};

export const duplicatePage = async (page: Page) => {
  const payload = ViewPB.fromObject(page);

  const result = await FolderEventDuplicateView(payload);

  if (result.ok) {
    return result.val;
  }

  return Promise.reject(result.err);
};

export const deletePage = async (id: string) => {
  const payload = new RepeatedViewIdPB({
    items: [id],
  });

  const result = await FolderEventDeleteView(payload);

  if (result.ok) {
    return result.val;
  }

  return Promise.reject(result.err);
};

export const createPage = async (params: ReturnType<typeof CreateViewPayloadPB.prototype.toObject>): Promise<string> => {
  const payload = CreateViewPayloadPB.fromObject(params);

  const result = await FolderEventCreateView(payload);

  if (result.ok) {
    return result.val.id;
  }

  return Promise.reject(result.err);
};

export const movePage = async (params: ReturnType<typeof MoveNestedViewPayloadPB.prototype.toObject>) => {
  const payload = new MoveNestedViewPayloadPB(params);

  const result = await FolderEventMoveNestedView(payload);

  if (result.ok) {
    return result.val;
  }

  return Promise.reject(result.err);
};

export const getChildPages = async (id: string): Promise<Page[]> => {
  const payload = new ViewIdPB({
    value: id,
  });

  const result = await FolderEventGetView(payload);

  if (result.ok) {
    return result.val.child_views.map(parserViewPBToPage);
  }

  return [];
};

export const updatePage = async (page: { id: string } & Partial<Page>) => {
  const payload = new UpdateViewPayloadPB();

  payload.view_id = page.id;
  if (page.name !== undefined) {
    payload.name = page.name;
  }

  const result = await FolderEventUpdateView(payload);

  if (result.ok) {
    return result.val.toObject();
  }

  return Promise.reject(result.err);
};

export const updatePageIcon = async (viewId: string, icon?: PageIcon) => {
  const payload = new UpdateViewIconPayloadPB({
    view_id: viewId,
    icon: icon
      ? new ViewIconPB({
          ty: icon.ty,
          value: icon.value,
        })
      : undefined,
  });

  const result = await FolderEventUpdateViewIcon(payload);

  if (result.ok) {
    return result.val;
  }

  return Promise.reject(result.err);
};

export async function setLatestOpenedPage(id: string) {
  const payload = new ViewIdPB({
    value: id,
  });

  const res = await FolderEventSetLatestView(payload);

  if (res.ok) {
    return res.val;
  }

  return Promise.reject(res.err);
}
