import { DatabaseBackendService } from './backend_service';
import { FieldController, FieldInfo } from './field/controller';
import { DatabaseViewCache } from './view/cache';
import { DatabasePB } from '../../../../services/backend/models/flowy-database/grid_entities';
import { RowChangedReason, RowInfo } from './row/cache';
import { Err } from 'ts-results';

export type SubscribeCallback = {
  onViewChanged: (data: DatabasePB) => void;
  onRowsChanged: (rowInfos: RowInfo[], reason: RowChangedReason) => void;
  onFieldsChanged: (fieldInfos: FieldInfo[]) => void;
};

export class DatabaseController {
  _backendService: DatabaseBackendService;
  _fieldController: FieldController;
  _databaseViewCache: DatabaseViewCache;
  _callback?: SubscribeCallback;

  constructor(public readonly viewId: string) {
    this._backendService = new DatabaseBackendService(viewId);
    this._fieldController = new FieldController(viewId);
    this._databaseViewCache = new DatabaseViewCache(viewId, this._fieldController);
  }

  subscribe = (callbacks: SubscribeCallback) => {
    this._callback = callbacks;
    this._fieldController.subscribeOnFieldsChanged(callbacks.onFieldsChanged);
  };

  open = async () => {
    const result = await this._backendService.openDatabase();
    if (result.ok) {
      const database: DatabasePB = result.val;
      this._callback?.onViewChanged(database);
      this._databaseViewCache.initializeWithRows(database.rows);
      return await this._fieldController.loadFields(database.fields);
    } else {
      return Err(result.val);
    }
  };

  createRow = async () => {
    return this._backendService.createRow();
  };

  dispose = async () => {
    await this._backendService.closeDatabase();
    await this._fieldController.dispose();
  };
}
