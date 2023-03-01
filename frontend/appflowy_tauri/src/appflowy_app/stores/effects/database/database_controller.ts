import { DatabaseBackendService } from './database_bd_svc';
import { FieldController, FieldInfo } from './field/field_controller';
import { DatabaseViewCache } from './view/database_view_cache';
import { DatabasePB } from '../../../../services/backend/models/flowy-database/grid_entities';
import { RowChangedReason, RowInfo } from './row/row_cache';
import { Err, Ok } from 'ts-results';

export type SubscribeCallback = {
  onViewChanged?: (data: DatabasePB) => void;
  onRowsChanged?: (rowInfos: readonly RowInfo[], reason: RowChangedReason) => void;
  onFieldsChanged?: (fieldInfos: readonly FieldInfo[]) => void;
};

export class DatabaseController {
  private backendService: DatabaseBackendService;
  fieldController: FieldController;
  databaseViewCache: DatabaseViewCache;
  private _callback?: SubscribeCallback;

  constructor(public readonly viewId: string) {
    this.backendService = new DatabaseBackendService(viewId);
    this.fieldController = new FieldController(viewId);
    this.databaseViewCache = new DatabaseViewCache(viewId, this.fieldController);
  }

  subscribe = (callbacks: SubscribeCallback) => {
    this._callback = callbacks;
    this.fieldController.subscribeOnFieldsChanged(callbacks.onFieldsChanged);
    this.databaseViewCache.getRowCache().subscribeOnRowsChanged((reason) => {
      this._callback?.onRowsChanged?.(this.databaseViewCache.rowInfos, reason);
    });
  };

  open = async () => {
    const result = await this.backendService.openDatabase();
    if (result.ok) {
      const database: DatabasePB = result.val;
      this._callback?.onViewChanged?.(database);
      await this.fieldController.loadFields(database.fields);
      await this.databaseViewCache.listenOnRowsChanged();
      await this.fieldController.listenOnFieldChanges();
      this.databaseViewCache.initializeWithRows(database.rows);
      return Ok.EMPTY;
    } else {
      return Err(result.val);
    }
  };

  createRow = async () => {
    return this.backendService.createRow();
  };

  dispose = async () => {
    await this.backendService.closeDatabase();
    await this.fieldController.dispose();
    await this.databaseViewCache.dispose();
  };
}
