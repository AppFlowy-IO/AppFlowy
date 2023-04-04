import { UpdateViewPayloadPB, RepeatedViewIdPB, ViewPB } from '@/services/backend';
import {
  FolderEventDeleteView,
  FolderEventDuplicateView,
  FolderEventUpdateView,
} from '@/services/backend/events/flowy-folder';

export class ViewBackendService {
  constructor(public readonly viewId: string) {}

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

  duplicate = (view: ViewPB) => {
    return FolderEventDuplicateView(view);
  };
}
