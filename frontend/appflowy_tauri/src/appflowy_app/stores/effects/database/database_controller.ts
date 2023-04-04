import { DatabaseBackendService } from './database_bd_svc';
import { FieldController, FieldInfo } from './field/field_controller';
import { DatabaseViewCache } from './view/database_view_cache';
import { DatabasePB, GroupPB, FlowyError } from '@/services/backend';
import { RowChangedReason, RowInfo } from './row/row_cache';
import { Err, Ok } from 'ts-results';
import { DatabaseGroupController } from './group/group_controller';
import { BehaviorSubject } from 'rxjs';
import { DatabaseGroupObserver } from './group/group_observer';
import { Log } from '$app/utils/log';

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
  private groupsObserver: DatabaseGroupObserver;

  constructor(public readonly viewId: string) {
    this.backendService = new DatabaseBackendService(viewId);
    this.fieldController = new FieldController(viewId);
    this.databaseViewCache = new DatabaseViewCache(viewId, this.fieldController);
    this.groups = new BehaviorSubject<DatabaseGroupController[]>([]);
    this.groupsObserver = new DatabaseGroupObserver(viewId);
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
      await this.databaseViewCache.initialize();
      await this.fieldController.initialize();

      // subscriptions
      await this.subscribeOnGroupsChanged();

      // load database initial data
      await this.fieldController.loadFields(database.fields);
      const loadGroupResult = await this.loadGroup();

      this.databaseViewCache.initializeWithRows(database.rows);

      this._callback?.onViewChanged?.(database);
      return loadGroupResult;
    } else {
      return Err(openDatabaseResult.val);
    }
  };

  getGroupByFieldId = async () => {
    const settingsResult = await this.backendService.getSettings();
    if (settingsResult.ok) {
      const settings = settingsResult.val;
      const groupConfig = settings.group_configurations.items;
      if (groupConfig.length === 0) {
        return Err(new FlowyError({ msg: 'this database has no groups' }));
      }
      return Ok(settings.group_configurations.items[0].field_id);
    } else {
      return Err(settingsResult.val);
    }
  };

  createRow = () => {
    return this.backendService.createRow();
  };

  moveRow = (rowId: string, groupId: string) => {
    return this.backendService.moveGroupRow(rowId, groupId);
  };

  exchangeRow = async (fromRowId: string, toRowId: string) => {
    await this.backendService.exchangeRow(fromRowId, toRowId);
    await this.loadGroup();
  };

  moveGroup = (fromGroupId: string, toGroupId: string) => {
    return this.backendService.moveGroup(fromGroupId, toGroupId);
  };

  moveField = (params: { fieldId: string; fromIndex: number; toIndex: number }) => {
    return this.backendService.moveField(params);
  };

  private loadGroup = async () => {
    const result = await this.backendService.loadGroups();
    if (result.ok) {
      const groups = result.val.items;
      await this.initialGroups(groups);
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
    this.groups.value;
  };

  private subscribeOnGroupsChanged = async () => {
    await this.groupsObserver.subscribe({
      onGroupBy: async (result) => {
        if (result.ok) {
          await this.initialGroups(result.val);
        }
      },
      onGroupChangeset: (result) => {
        if (result.err) {
          Log.error(result.val);
          return;
        }
        const changeset = result.val;
        let existControllers = [...this.groups.getValue()];
        for (const deleteId of changeset.deleted_groups) {
          existControllers = existControllers.filter((c) => c.groupId !== deleteId);
        }

        for (const update of changeset.update_groups) {
          const index = existControllers.findIndex((c) => c.groupId === update.group_id);
          if (index !== -1) {
            existControllers[index].updateGroup(update);
          }
        }

        for (const insert of changeset.inserted_groups) {
          const controller = new DatabaseGroupController(insert.group, this.backendService);
          if (insert.index > existControllers.length) {
            existControllers.push(controller);
          } else {
            existControllers.splice(insert.index, 0, controller);
          }
        }
        this.groups.next(existControllers);
      },
    });
  };

  dispose = async () => {
    this.groups.value.forEach((group) => {
      void group.dispose();
    });
    await this.groupsObserver.unsubscribe();
    await this.backendService.closeDatabase();
    await this.fieldController.dispose();
    await this.databaseViewCache.dispose();
  };
}
