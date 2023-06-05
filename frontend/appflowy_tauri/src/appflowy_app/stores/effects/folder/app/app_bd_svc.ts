import {
  FolderEventCreateView,
  FolderEventDeleteView,
  FolderEventMoveView,
  FolderEventReadView,
  FolderEventUpdateView,
  ViewLayoutPB,
} from '@/services/backend/events/flowy-folder2';
import {
  CreateViewPayloadPB,
  RepeatedViewIdPB,
  ViewPB,
  MoveViewPayloadPB,
  FlowyError,
  ViewIdPB,
  UpdateViewPayloadPB,
} from '@/services/backend';
import { None, Result, Some } from 'ts-results';

export class AppBackendService {
  constructor(public readonly appId: string) {}

  getApp = () => {
    const payload = ViewIdPB.fromObject({ value: this.appId });
    return FolderEventReadView(payload);
  };

  createView = async (params: {
    name: string;
    desc?: string;
    layoutType: ViewLayoutPB;
    /// The initial data should be the JSON of the document
    /// For example: {"document":{"type":"editor","children":[]}}
    initialData?: string;
  }) => {
    const encoder = new TextEncoder();
    const payload = CreateViewPayloadPB.fromObject({
      parent_view_id: this.appId,
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
    const payload = ViewIdPB.fromObject({ value: this.appId });
    return FolderEventReadView(payload).then((result) => {
      return result.map((app) => app.child_views);
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
    const payload = UpdateViewPayloadPB.fromObject({ view_id: this.appId, name: params.name });
    const result = await FolderEventUpdateView(payload);
    if (!result.ok) {
      throw new Error(result.val.msg);
    }
  };

  delete = async () => {
    const payload = RepeatedViewIdPB.fromObject({ items: [this.appId] });
    const result = await FolderEventDeleteView(payload);
    if (!result.ok) {
      throw new Error(result.val.msg);
    }
  };

  deleteView = (viewId: string) => {
    const payload = RepeatedViewIdPB.fromObject({ items: [viewId] });
    return FolderEventDeleteView(payload);
  };

  moveView = (params: { view_id: string; fromIndex: number; toIndex: number }) => {
    const payload = MoveViewPayloadPB.fromObject({
      view_id: params.view_id,
      from: params.fromIndex,
      to: params.toIndex,
    });

    return FolderEventMoveView(payload);
  };
}
