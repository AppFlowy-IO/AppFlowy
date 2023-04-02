import { DatabaseViewRowsObserver } from './view_row_observer';
import { RowCache, RowInfo } from '../row/row_cache';
import { FieldController } from '../field/field_controller';
import { RowPB } from '@/services/backend';

export class DatabaseViewCache {
  private readonly rowsObserver: DatabaseViewRowsObserver;
  private readonly rowCache: RowCache;

  constructor(public readonly viewId: string, fieldController: FieldController) {
    this.rowsObserver = new DatabaseViewRowsObserver(viewId);
    this.rowCache = new RowCache(viewId, () => fieldController.fieldInfos);
    fieldController.subscribe({
      onNumOfFieldsChanged: (fieldInfos) => {
        fieldInfos.forEach((fieldInfo) => {
          this.rowCache.onFieldUpdated(fieldInfo);
        });
        this.rowCache.onNumberOfFieldsUpdated(fieldInfos);
      },
    });
  }

  initializeWithRows = (rows: RowPB[]) => {
    this.rowCache.initializeRows(rows);
  };

  get rowInfos(): readonly RowInfo[] {
    return this.rowCache.rows;
  }

  getRowCache = () => {
    return this.rowCache;
  };

  dispose = async () => {
    await this.rowsObserver.unsubscribe();
    await this.rowCache.dispose();
  };

  initialize = async () => {
    await this.rowsObserver.subscribe({
      onRowsVisibilityChanged: (result) => {
        if (result.ok) {
          this.rowCache.applyRowsVisibility(result.val);
        }
      },
      onNumberOfRowsChanged: (result) => {
        if (result.ok) {
          this.rowCache.applyRowsChanged(result.val);
        }
      },
      onReorderRows: (result) => {
        if (result.ok) {
          this.rowCache.applyReorderRows(result.val);
        }
      },
      onReorderSingleRow: (result) => {
        if (result.ok) {
          this.rowCache.applyReorderSingleRow(result.val);
        }
      },
    });
  };
}
