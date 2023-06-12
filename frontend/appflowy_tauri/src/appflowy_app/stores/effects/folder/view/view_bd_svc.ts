import { UpdateViewPayloadPB, RepeatedViewIdPB, ViewPB, FlowyError, ViewIdPB } from '@/services/backend';
import {
  FolderEventDeleteView,
  FolderEventDuplicateView,
  FolderEventReadView,
  FolderEventUpdateView,
} from '@/services/backend/events/flowy-folder2';
import { Ok, Result } from 'ts-results';

export class ViewBackendService {
  constructor(public readonly viewId: string) {}

  getChildViews = async (): Promise<Result<ViewPB[], FlowyError>> => {
    const payload = ViewIdPB.fromObject({ value: this.viewId });
    const result = await FolderEventReadView(payload);
    if (result.ok) {
      return Ok(result.val.child_views);
    } else {
      return result;
    }
  };

  update = (params: { name?: string; desc?: string }) => {
    const payload = UpdateViewPayloadPB.fromObject({ view_id: this.viewId });

    if (params.name !== undefined) {
      payload.name = params.name;
    }
    if (params.desc !== undefined) {
      payload.desc = params.desc;
    }

    return FolderEventUpdateView(payload);
  };

  delete = () => {
    const payload = RepeatedViewIdPB.fromObject({ items: [this.viewId] });
    return FolderEventDeleteView(payload);
  };

  duplicate = async () => {
    const view = await FolderEventReadView(ViewIdPB.fromObject({ value: this.viewId }));
    if (view.ok) {
      return FolderEventDuplicateView(view.val);
    } else {
      return view;
    }
  };
}
