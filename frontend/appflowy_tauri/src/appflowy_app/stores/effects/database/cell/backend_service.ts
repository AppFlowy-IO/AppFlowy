import { DatabaseEventGetCell, DatabaseEventUpdateCell } from '../../../../../services/backend/events/flowy-database';
import { CellChangesetPB, CellIdPB } from '../../../../../services/backend/models/flowy-database/cell_entities';

class CellIdentifier {
  constructor(public readonly databaseId: string, public readonly rowId: string, public readonly fieldId: string) {}
}

class CellBackendService {
  static updateCell = async (cellId: CellIdentifier, data: string) => {
    const payload = CellChangesetPB.fromObject({
      database_id: cellId.databaseId,
      field_id: cellId.fieldId,
      row_id: cellId.rowId,
      type_cell_data: data,
    });
    return DatabaseEventUpdateCell(payload);
  };

  static getCell = async (cellId: CellIdentifier) => {
    const payload = CellIdPB.fromObject({
      database_id: cellId.databaseId,
      field_id: cellId.fieldId,
      row_id: cellId.rowId,
    });

    return DatabaseEventGetCell(payload);
  };
}

export { CellBackendService, CellIdentifier };
