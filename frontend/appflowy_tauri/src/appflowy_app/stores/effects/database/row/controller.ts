import { CellByFieldId, RowCache, RowInfo } from './cache';
import { FieldController } from '../field/controller';

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
