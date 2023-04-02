import { DatabaseNotification, FlowyError, GroupPB, GroupRowsNotificationPB, RowPB } from '@/services/backend';
import { ChangeNotifier } from '$app/utils/change_notifier';
import { None, Ok, Option, Result, Some } from 'ts-results';
import { DatabaseNotificationObserver } from '../notifications/observer';
import { Log } from '$app/utils/log';
import { DatabaseBackendService } from '../database_bd_svc';

export type GroupDataCallbacks = {
  onRemoveRow: (groupId: string, rowId: string) => void;
  onInsertRow: (groupId: string, row: RowPB, index?: number) => void;
  onUpdateRow: (groupId: string, row: RowPB) => void;

  onCreateRow: (groupId: string, row: RowPB) => void;
};

export class DatabaseGroupController {
  private dataObserver: GroupDataObserver;
  private callbacks?: GroupDataCallbacks;

  constructor(private group: GroupPB, private databaseBackendSvc: DatabaseBackendService) {
    this.dataObserver = new GroupDataObserver(group.group_id);
  }

  get groupId() {
    return this.group.group_id;
  }

  get rows() {
    return this.group.rows;
  }

  get name() {
    return this.group.desc;
  }

  updateGroup = (group: GroupPB) => {
    this.group = group;
  };

  rowAtIndex = (index: number): Option<RowPB> => {
    if (this.group.rows.length < index) {
      return None;
    }
    return Some(this.group.rows[index]);
  };

  initialize = async () => {
    await this.dataObserver.subscribe({
      onRowsChanged: (result) => {
        if (result.ok) {
          const changeset = result.val;
          // Delete
          changeset.deleted_rows.forEach((deletedRowId) => {
            this.group.rows = this.group.rows.filter((row) => row.id !== deletedRowId);
            this.callbacks?.onRemoveRow(this.group.group_id, deletedRowId);
          });

          // Insert
          changeset.inserted_rows.forEach((insertedRow) => {
            let index: number | undefined = insertedRow.index;
            if (insertedRow.has_index && this.group.rows.length > insertedRow.index) {
              this.group.rows.splice(index, 0, insertedRow.row);
            } else {
              index = undefined;
              this.group.rows.push(insertedRow.row);
            }

            if (insertedRow.is_new) {
              this.callbacks?.onCreateRow(this.group.group_id, insertedRow.row);
            } else {
              this.callbacks?.onInsertRow(this.group.group_id, insertedRow.row, index);
            }
          });

          // Update
          changeset.updated_rows.forEach((updatedRow) => {
            const index = this.group.rows.findIndex((row) => row.id === updatedRow.id);
            if (index !== -1) {
              this.group.rows[index] = updatedRow;
              this.callbacks?.onUpdateRow(this.group.group_id, updatedRow);
            }
          });
        } else {
          Log.error(result.val);
        }
      },
    });
  };

  createRow = async () => {
    return this.databaseBackendSvc.createRow({ groupId: this.group.group_id });
  };

  subscribe = (callbacks: GroupDataCallbacks) => {
    this.callbacks = callbacks;
  };

  unsubscribe = () => {
    this.callbacks = undefined;
  };

  dispose = async () => {
    await this.dataObserver.unsubscribe();
    this.callbacks = undefined;
  };
}

type GroupRowsSubscribeCallback = (value: Result<GroupRowsNotificationPB, FlowyError>) => void;

class GroupDataObserver {
  private notifier?: ChangeNotifier<Result<GroupRowsNotificationPB, FlowyError>>;
  private listener?: DatabaseNotificationObserver;

  constructor(public readonly groupId: string) {}

  subscribe = async (callbacks: { onRowsChanged: GroupRowsSubscribeCallback }) => {
    this.notifier = new ChangeNotifier();
    this.notifier?.observer.subscribe(callbacks.onRowsChanged);

    this.listener = new DatabaseNotificationObserver({
      id: this.groupId,
      parserHandler: (notification, result) => {
        switch (notification) {
          case DatabaseNotification.DidUpdateGroupRow:
            if (result.ok) {
              this.notifier?.notify(Ok(GroupRowsNotificationPB.deserializeBinary(result.val)));
            } else {
              this.notifier?.notify(result);
            }
            return;
          default:
            break;
        }
      },
    });
    await this.listener.start();
  };

  unsubscribe = async () => {
    await this.listener?.stop();
    this.notifier?.unsubscribe();
  };
}
