import { DatabaseEventGetCell, DatabaseEventUpdateCell } from '@/services/backend/events/flowy-database';
import { CellChangesetPB, CellIdPB, FieldType } from '@/services/backend';

class CellIdentifier {
  constructor(
    public readonly viewId: string,
    public readonly rowId: string,
    public readonly fieldId: string,
    public readonly fieldType: FieldType
  ) {}
}

class CellBackendService {
  static updateCell = async (cellId: CellIdentifier, data: string) => {
    const payload = CellChangesetPB.fromObject({
      view_id: cellId.viewId,
      field_id: cellId.fieldId,
      row_id: cellId.rowId,
      type_cell_data: data,
    });
    return DatabaseEventUpdateCell(payload);
  };

  getCell = async (cellId: CellIdentifier) => {
    const payload = CellIdPB.fromObject({
      view_id: cellId.viewId,
      field_id: cellId.fieldId,
      row_id: cellId.rowId,
    });

    return DatabaseEventGetCell(payload);
  };
}

export { CellBackendService, CellIdentifier };
