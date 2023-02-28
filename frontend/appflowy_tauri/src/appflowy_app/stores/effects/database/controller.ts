import { DatabaseBackendService } from './backend_service';
import { FieldController, FieldInfo } from './field/controller';
import { DatabaseViewCache } from './view/cache';
import { DatabasePB } from '../../../../services/backend/models/flowy-database/grid_entities';
import { RowChangedReason, RowInfo } from './row/cache';
import { Err, Ok } from 'ts-results';

export type SubscribeCallback = {
  onViewChanged: (data: DatabasePB) => void;
  onRowsChanged: (rowInfos: readonly RowInfo[], reason: RowChangedReason) => void;
  onFieldsChanged: (fieldInfos: readonly FieldInfo[]) => void;
};

export class DatabaseController {
  private _backendService: DatabaseBackendService;
  fieldController: FieldController;
  databaseViewCache: DatabaseViewCache;
  private _callback?: SubscribeCallback;

  constructor(public readonly viewId: string) {
    this._backendService = new DatabaseBackendService(viewId);
    this.fieldController = new FieldController(viewId);
    this.databaseViewCache = new DatabaseViewCache(viewId, this.fieldController);
  }

  subscribe = (callbacks: SubscribeCallback) => {
    this._callback = callbacks;
    this.fieldController.subscribeOnFieldsChanged(callbacks.onFieldsChanged);
    this.databaseViewCache.subscribeOnRowsChanged((reason) => {
      this._callback?.onRowsChanged(this.databaseViewCache.rowInfos, reason);
    });
  };

  open = async () => {
    const result = await this._backendService.openDatabase();
    if (result.ok) {
      const database: DatabasePB = result.val;
      this._callback?.onViewChanged(database);
      await this.fieldController.loadFields(database.fields);
      this.databaseViewCache.initializeWithRows(database.rows);
      return Ok.EMPTY;
    } else {
      return Err(result.val);
    }
  };

  createRow = async () => {
    return this._backendService.createRow();
  };

  dispose = async () => {
    await this._backendService.closeDatabase();
    await this.fieldController.dispose();
    await this.databaseViewCache.dispose();
  };
}
