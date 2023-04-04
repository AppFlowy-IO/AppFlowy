import { CreateRowPayloadPB, RowIdPB } from '@/services/backend';
import {
  DatabaseEventCreateRow,
  DatabaseEventDeleteRow,
  DatabaseEventDuplicateRow,
  DatabaseEventGetRow,
} from '@/services/backend/events/flowy-database';

export class RowBackendService {
  constructor(public readonly viewId: string) {}

  // Create a row below the row with rowId
  createRow = (rowId: string) => {
    const payload = CreateRowPayloadPB.fromObject({ view_id: this.viewId, start_row_id: rowId });
    return DatabaseEventCreateRow(payload);
  };

  deleteRow = (rowId: string) => {
    const payload = RowIdPB.fromObject({ view_id: this.viewId, row_id: rowId });
    return DatabaseEventDeleteRow(payload);
  };

  duplicateRow = (rowId: string) => {
    const payload = RowIdPB.fromObject({ view_id: this.viewId, row_id: rowId });
    return DatabaseEventDuplicateRow(payload);
  };

  getRow = (rowId: string) => {
    const payload = RowIdPB.fromObject({ view_id: this.viewId, row_id: rowId });
    return DatabaseEventGetRow(payload);
  };
}
