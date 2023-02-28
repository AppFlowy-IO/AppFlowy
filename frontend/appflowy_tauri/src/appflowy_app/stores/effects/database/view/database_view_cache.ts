import { DatabaseViewRowsObserver } from './view_row_observer';
import { RowCache, RowChangedReason, RowInfo } from '../row/row_cache';
import { FieldController } from '../field/field_controller';
import { RowPB } from '../../../../../services/backend/models/flowy-database/row_entities';
import { Subscription } from 'rxjs';

export class DatabaseViewCache {
  private readonly _rowsObserver: DatabaseViewRowsObserver;
  private readonly _rowCache: RowCache;
  private readonly _fieldSubscription?: Subscription;

  constructor(public readonly viewId: string, fieldController: FieldController) {
    this._rowsObserver = new DatabaseViewRowsObserver(viewId);
    this._rowCache = new RowCache(viewId, () => fieldController.fieldInfos);
    this._fieldSubscription = fieldController.subscribeOnFieldsChanged((fieldInfos) => {
      fieldInfos.forEach((fieldInfo) => {
        this._rowCache.onFieldUpdated(fieldInfo);
      });
    });
    this._listenOnRowsChanged();
  }

  initializeWithRows = (rows: RowPB[]) => {
    this._rowCache.initializeRows(rows);
  };

  get rowInfos(): readonly RowInfo[] {
    return this._rowCache.rows;
  }

  getRowCache = () => {
    return this._rowCache;
  };

  dispose = async () => {
    this._fieldSubscription?.unsubscribe();
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
