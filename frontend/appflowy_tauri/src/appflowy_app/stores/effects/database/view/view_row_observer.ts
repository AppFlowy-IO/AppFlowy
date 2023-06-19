import { Ok, Result } from 'ts-results';
import {
  DatabaseNotification,
  FlowyError,
  ReorderAllRowsPB,
  ReorderSingleRowPB,
  RowsChangePB,
  RowsVisibilityChangePB,
} from '@/services/backend';
import { ChangeNotifier } from '$app/utils/change_notifier';
import { DatabaseNotificationObserver } from '../notifications/observer';

export type RowsVisibilityNotifyValue = Result<RowsVisibilityChangePB, FlowyError>;
export type RowsNotifyValue = Result<RowsChangePB, FlowyError>;
export type ReorderRowsNotifyValue = Result<string[], FlowyError>;
export type ReorderSingleRowNotifyValue = Result<ReorderSingleRowPB, FlowyError>;

export class DatabaseViewRowsObserver {
  private rowsVisibilityNotifier = new ChangeNotifier<RowsVisibilityNotifyValue>();
  private rowsNotifier = new ChangeNotifier<RowsNotifyValue>();
  private reorderRowsNotifier = new ChangeNotifier<ReorderRowsNotifyValue>();
  private reorderSingleRowNotifier = new ChangeNotifier<ReorderSingleRowNotifyValue>();

  private _listener?: DatabaseNotificationObserver;

  constructor(public readonly viewId: string) {}

  subscribe = async (callbacks: {
    onRowsVisibilityChanged?: (value: RowsVisibilityNotifyValue) => void;
    onNumberOfRowsChanged?: (value: RowsNotifyValue) => void;
    onReorderRows?: (value: ReorderRowsNotifyValue) => void;
    onReorderSingleRow?: (value: ReorderSingleRowNotifyValue) => void;
  }) => {
    //
    this.rowsVisibilityNotifier.observer?.subscribe(callbacks.onRowsVisibilityChanged);
    this.rowsNotifier.observer?.subscribe(callbacks.onNumberOfRowsChanged);
    this.reorderRowsNotifier.observer?.subscribe(callbacks.onReorderRows);
    this.reorderSingleRowNotifier.observer?.subscribe(callbacks.onReorderSingleRow);

    this._listener = new DatabaseNotificationObserver({
      id: this.viewId,
      parserHandler: (notification, result) => {
        switch (notification) {
          case DatabaseNotification.DidUpdateViewRowsVisibility:
            if (result.ok) {
              this.rowsVisibilityNotifier.notify(Ok(RowsVisibilityChangePB.deserializeBinary(result.val)));
            } else {
              this.rowsVisibilityNotifier.notify(result);
            }
            break;
          case DatabaseNotification.DidUpdateViewRows:
            if (result.ok) {
              this.rowsNotifier.notify(Ok(RowsChangePB.deserializeBinary(result.val)));
            } else {
              this.rowsNotifier.notify(result);
            }
            break;
          case DatabaseNotification.DidReorderRows:
            if (result.ok) {
              this.reorderRowsNotifier.notify(Ok(ReorderAllRowsPB.deserializeBinary(result.val).row_orders));
            } else {
              this.reorderRowsNotifier.notify(result);
            }
            break;
          case DatabaseNotification.DidReorderSingleRow:
            if (result.ok) {
              this.reorderSingleRowNotifier.notify(Ok(ReorderSingleRowPB.deserializeBinary(result.val)));
            } else {
              this.reorderSingleRowNotifier.notify(result);
            }
            break;
          default:
            break;
        }
      },
    });
    await this._listener.start();
  };

  unsubscribe = async () => {
    this.rowsVisibilityNotifier.unsubscribe();
    this.reorderRowsNotifier.unsubscribe();
    this.rowsNotifier.unsubscribe();
    this.reorderSingleRowNotifier.unsubscribe();
    await this._listener?.stop();
  };
}
