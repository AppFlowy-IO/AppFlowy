import {
  DatabaseEventCreateRow,
  DatabaseEventGetDatabase,
  DatabaseEventGetFields,
} from '../../../../services/backend/events/flowy-database';
import {
  GetFieldPayloadPB,
  RepeatedFieldIdPB,
  FieldIdPB,
  DatabaseViewIdPB,
  CreateRowPayloadPB,
  ViewIdPB,
} from '../../../../services/backend';
import { FolderEventCloseView } from '../../../../services/backend/events/flowy-folder';

export class DatabaseBackendService {
  viewId: string;

  constructor(viewId: string) {
    this.viewId = viewId;
  }

  openDatabase = async () => {
    const payload = DatabaseViewIdPB.fromObject({
      value: this.viewId,
    });
    return DatabaseEventGetDatabase(payload);
  };

  closeDatabase = async () => {
    const payload = ViewIdPB.fromObject({ value: this.viewId });
    return FolderEventCloseView(payload);
  };

  createRow = async (rowId?: string) => {
    const props = { database_id: this.viewId, start_row_id: rowId ?? undefined };
    const payload = CreateRowPayloadPB.fromObject(props);
    return DatabaseEventCreateRow(payload);
  };

  getFields = async (fieldIds?: FieldIdPB[]) => {
    const payload = GetFieldPayloadPB.fromObject({ view_id: this.viewId });

    if (!fieldIds) {
      payload.field_ids = RepeatedFieldIdPB.fromObject({ items: fieldIds });
    }

    return DatabaseEventGetFields(payload).then((result) => result.map((value) => value.items));
  };
}
