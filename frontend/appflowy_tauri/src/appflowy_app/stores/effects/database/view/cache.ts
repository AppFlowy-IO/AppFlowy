import { DatabaseViewRowsObserver } from './row_observer';
import { RowCache, RowChangedReason } from '../row/cache';
import { FieldController } from '../field/controller';
import { RowPB } from '../../../../../services/backend/models/flowy-database/row_entities';

export class DatabaseViewCache {
  _rowsObserver: DatabaseViewRowsObserver;
  _rowCache: RowCache;

  constructor(public readonly viewId: string, fieldController: FieldController) {
    this._rowsObserver = new DatabaseViewRowsObserver(viewId);
    this._rowCache = new RowCache(viewId, () => fieldController.fieldInfos);
    this._listenOnRowsChanged();
  }

  initializeWithRows = (rows: RowPB[]) => {
    this._rowCache.initializeRows(rows);
  };

  subscribeOnRowsChanged = (onRowsChanged: (reason: RowChangedReason) => void) => {
    return this._rowCache.subscribeOnRowsChanged((reason) => {
      onRowsChanged(reason);
    });
  };

  dispose = async () => {
    await this._rowsObserver.unsubscribe();
    await this._rowCache.dispose();
  };

  _listenOnRowsChanged = () => {
    this._rowsObserver.subscribe({
      onRowsVisibilityChanged: (result) => {
        if (result.ok) {
          this._rowCache.applyRowsVisibility(result.val);
        }
      },
      onNumberOfRowsChanged: (result) => {
        if (result.ok) {
          this._rowCache.applyRowsChanged(result.val);
        }
      },
      onReorderRows: (result) => {
        if (result.ok) {
          this._rowCache.applyReorderRows(result.val);
        }
      },
      onReorderSingleRow: (result) => {
        if (result.ok) {
          this._rowCache.applyReorderSingleRow(result.val);
        }
      },
    });
  };
}
