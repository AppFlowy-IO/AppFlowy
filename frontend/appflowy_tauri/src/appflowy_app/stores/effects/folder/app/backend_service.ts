import {
  FolderEventCreateView,
  FolderEventDeleteApp,
  FolderEventDeleteView,
  FolderEventMoveItem,
  FolderEventReadApp,
  FolderEventUpdateApp,
  ViewDataFormatPB,
  ViewLayoutTypePB,
} from '../../../../../services/backend/events/flowy-folder';
import { AppIdPB, UpdateAppPayloadPB } from '../../../../../services/backend/models/flowy-folder/app';
import {
  CreateViewPayloadPB,
  RepeatedViewIdPB,
  ViewPB,
  MoveFolderItemPayloadPB,
  MoveFolderItemType,
} from '../../../../../services/backend/models/flowy-folder/view';
import { FlowyError } from '../../../../../services/backend/models/flowy-error/errors';
import { None, Result, Some } from 'ts-results';

export class AppBackendService {
  constructor(public readonly appId: string) {}

  getApp = () => {
    const payload = AppIdPB.fromObject({ value: this.appId });
    return FolderEventReadApp(payload);
  };

  createView = (params: {
    name: string;
    desc?: string;
    dataFormatType: ViewDataFormatPB;
    layoutType: ViewLayoutTypePB;
    /// The initial data should be the JSON of the doucment
    /// For example: {"document":{"type":"editor","children":[]}}
    initialData?: string;
  }) => {
    const encoder = new TextEncoder();
    const payload = CreateViewPayloadPB.fromObject({
      belong_to_id: this.appId,
      name: params.name,
      desc: params.desc || '',
      data_format: params.dataFormatType,
      layout: params.layoutType,
      initial_data: encoder.encode(params.initialData || ''),
    });

    return FolderEventCreateView(payload);
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

  update = (params: { name: string }) => {
    const payload = UpdateAppPayloadPB.fromObject({ app_id: this.appId, name: params.name });
    return FolderEventUpdateApp(payload);
  };

  delete = () => {
    const payload = AppIdPB.fromObject({ value: this.appId });
    return FolderEventDeleteApp(payload);
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
