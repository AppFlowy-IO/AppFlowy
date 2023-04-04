import {
  FolderEventCreateView,
  FolderEventDeleteApp,
  FolderEventDeleteView,
  FolderEventMoveItem,
  FolderEventReadApp,
  FolderEventUpdateApp,
  ViewLayoutTypePB,
} from '@/services/backend/events/flowy-folder';
import {
  AppIdPB,
  UpdateAppPayloadPB,
  CreateViewPayloadPB,
  RepeatedViewIdPB,
  ViewPB,
  MoveFolderItemPayloadPB,
  MoveFolderItemType,
  FlowyError,
} from '@/services/backend';
import { None, Result, Some } from 'ts-results';

export class AppBackendService {
  constructor(public readonly appId: string) {}

  getApp = () => {
    const payload = AppIdPB.fromObject({ value: this.appId });
    return FolderEventReadApp(payload);
  };

  createView = async (params: {
    name: string;
    desc?: string;
    layoutType: ViewLayoutTypePB;
    /// The initial data should be the JSON of the document
    /// For example: {"document":{"type":"editor","children":[]}}
    initialData?: string;
  }) => {
    const encoder = new TextEncoder();
    const payload = CreateViewPayloadPB.fromObject({
      belong_to_id: this.appId,
      name: params.name,
      desc: params.desc || '',
      layout: params.layoutType,
      initial_data: encoder.encode(params.initialData || ''),
    });

    const result = await FolderEventCreateView(payload);

    if (result.ok) {
      return result.val;
    } else {
      throw new Error(result.val.msg);
    }
  };

  getAllViews = (): Promise<Result<ViewPB[], FlowyError>> => {
    const payload = AppIdPB.fromObject({ value: this.appId });
    return FolderEventReadApp(payload).then((result) => {
      return result.map((app) => app.belongings.items);
    });
  };

  getView = async (viewId: string) => {
    const result = await this.getAllViews();
    if (result.ok) {
      const target = result.val.find((view) => view.id === viewId);
      if (target !== undefined) {
        return Some(target);
      } else {
        return None;
      }
    } else {
      return None;
    }
  };

  update = async (params: { name: string }) => {
    const payload = UpdateAppPayloadPB.fromObject({ app_id: this.appId, name: params.name });
    const result = await FolderEventUpdateApp(payload);
    if (!result.ok) {
      throw new Error(result.val.msg);
    }
  };

  delete = async () => {
    const payload = AppIdPB.fromObject({ value: this.appId });
    const result = await FolderEventDeleteApp(payload);
    if (!result.ok) {
      throw new Error(result.val.msg);
    }
  };

  deleteView = (viewId: string) => {
    const payload = RepeatedViewIdPB.fromObject({ items: [viewId] });
    return FolderEventDeleteView(payload);
  };

  moveView = (params: { view_id: string; fromIndex: number; toIndex: number }) => {
    const payload = MoveFolderItemPayloadPB.fromObject({
      item_id: params.view_id,
      from: params.fromIndex,
      to: params.toIndex,
      ty: MoveFolderItemType.MoveView,
    });

    return FolderEventMoveItem(payload);
  };
}
