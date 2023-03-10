import { CellByFieldId, RowCache, RowInfo } from './row_cache';
import { FieldController } from '../field/field_controller';

export class RowController {
  constructor(
    public readonly rowInfo: RowInfo,
    public readonly fieldController: FieldController,
    private readonly cache: RowCache
  ) {
    //
  }

  loadCells = async (): Promise<CellByFieldId> => {
    return this.cache.loadCells(this.rowInfo.row.id);
  };
}
