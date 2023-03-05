import { DatabaseBackendService } from './database_bd_svc';
import { FieldController, FieldInfo } from './field/field_controller';
import { DatabaseViewCache } from './view/database_view_cache';
import { DatabasePB, GroupPB } from '../../../../services/backend';
import { RowChangedReason, RowInfo } from './row/row_cache';
import { Err } from 'ts-results';
import { DatabaseGroupController } from './group/group_controller';
import { BehaviorSubject } from 'rxjs';

export type DatabaseSubscriberCallbacks = {
  onViewChanged?: (data: DatabasePB) => void;
  onRowsChanged?: (rowInfos: readonly RowInfo[], reason: RowChangedReason) => void;
  onFieldsChanged?: (fieldInfos: readonly FieldInfo[]) => void;
  onGroupByField?: (groups: GroupPB[]) => void;

  onNumOfGroupChanged?: {
    onUpdateGroup: (value: GroupPB[]) => void;
    onDeleteGroup: (value: GroupPB[]) => void;
    onInsertGroup: (value: GroupPB[]) => void;
  };
};

export class DatabaseController {
  private readonly backendService: DatabaseBackendService;
  fieldController: FieldController;
  databaseViewCache: DatabaseViewCache;
  private _callback?: DatabaseSubscriberCallbacks;
  public groups: BehaviorSubject<DatabaseGroupController[]>;

  constructor(public readonly viewId: string) {
    this.backendService = new DatabaseBackendService(viewId);
    this.fieldController = new FieldController(viewId);
    this.databaseViewCache = new DatabaseViewCache(viewId, this.fieldController);
    this.groups = new BehaviorSubject<DatabaseGroupController[]>([]);
  }

  subscribe = (callbacks: DatabaseSubscriberCallbacks) => {
    this._callback = callbacks;
    this.fieldController.subscribe({ onNumOfFieldsChanged: callbacks.onFieldsChanged });
    this.databaseViewCache.getRowCache().subscribe({
      onRowsChanged: (reason) => {
        this._callback?.onRowsChanged?.(this.databaseViewCache.rowInfos, reason);
      },
    });
  };

  open = async () => {
    const openDatabaseResult = await this.backendService.openDatabase();
    if (openDatabaseResult.ok) {
      const database: DatabasePB = openDatabaseResult.val;
      this._callback?.onViewChanged?.(database);

      // listeners
      await this.databaseViewCache.initialize();
      await this.fieldController.initialize();

      // load database initial data
      await this.fieldController.loadFields(database.fields);
      const loadGroupResult = await this.loadGroup();

      this.databaseViewCache.initializeWithRows(database.rows);
      return loadGroupResult;
    } else {
      return Err(openDatabaseResult.val);
    }
  };

  createRow = async () => {
    return this.backendService.createRow();
  };

  private loadGroup = async () => {
    const result = await this.backendService.loadGroups();
    if (result.ok) {
      const groups = result.val.items;
      await this.initialGroups(groups);
      this._callback?.onGroupByField?.(groups);
    }
    return result;
  };

  private initialGroups = async (groups: GroupPB[]) => {
    this.groups.getValue().forEach((controller) => {
      void controller.dispose();
    });

    const controllers: DatabaseGroupController[] = [];
    for (const groupPB of groups) {
      const controller = new DatabaseGroupController(groupPB, this.backendService);
      await controller.initialize();
      controllers.push(controller);
    }
    this.groups.next(controllers);
  };

  dispose = async () => {
    await this.backendService.closeDatabase();
    await this.fieldController.dispose();
    await this.databaseViewCache.dispose();
  };
}
