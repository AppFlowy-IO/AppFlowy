import { Result } from 'ts-results';
import { FlowyError } from '../../../../../services/backend/models/flowy-error';
import { CellBackendService, CellIdentifier } from './backend_service';

export abstract class CellDataPersistence<D> {
  abstract save(data: D): Promise<Result<void, FlowyError>>;
}

export class TextCellDataPersistence extends CellDataPersistence<string> {
  constructor(public readonly cellId: CellIdentifier) {
    super();
  }

  save(data: string): Promise<Result<void, FlowyError>> {
    return CellBackendService.updateCell(this.cellId, data);
  }
}
