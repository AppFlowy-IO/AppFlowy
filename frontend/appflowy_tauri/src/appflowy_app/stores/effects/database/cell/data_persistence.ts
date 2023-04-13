import { Result } from 'ts-results';
import { CellBackendService, CellIdentifier } from './cell_bd_svc';
import { CalendarData } from './controller_builder';
import { DateChangesetPB, FlowyError, CellIdPB } from '@/services/backend';
import { DatabaseEventUpdateDateCell } from '@/services/backend/events/flowy-database';

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

export class DateCellDataPersistence extends CellDataPersistence<CalendarData> {
  constructor(public readonly cellIdentifier: CellIdentifier) {
    super();
  }

  save(data: CalendarData): Promise<Result<void, FlowyError>> {
    const payload = DateChangesetPB.fromObject({ cell_path: _makeCellPath(this.cellIdentifier) });
    payload.date = ((data.date.getTime() / 1000) | 0).toString();
    payload.is_utc = true;
    if (data.time !== undefined) {
      payload.time = data.time;
    }
    payload.include_time = data.includeTime;
    return DatabaseEventUpdateDateCell(payload);
  }
}

function _makeCellPath(cellIdentifier: CellIdentifier): CellIdPB {
  return CellIdPB.fromObject({
    view_id: cellIdentifier.viewId,
    field_id: cellIdentifier.fieldId,
    row_id: cellIdentifier.rowId,
  });
}
