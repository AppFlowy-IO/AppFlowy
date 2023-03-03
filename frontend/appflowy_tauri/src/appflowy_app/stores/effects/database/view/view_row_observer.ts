import { Ok, Result } from 'ts-results';
import {
  DatabaseNotification,
  FlowyError,
  ReorderAllRowsPB,
  ReorderSingleRowPB,
  RowsChangesetPB,
  RowsVisibilityChangesetPB,
} from '../../../../../services/backend';
import { ChangeNotifier } from '../../../../utils/change_notifier';
import { DatabaseNotificationObserver } from '../notifications/observer';

export type RowsVisibilityNotifyValue = Result<RowsVisibilityChangesetPB, FlowyError>;
export type RowsNotifyValue = Result<RowsChangesetPB, FlowyError>;
export type ReorderRowsNotifyValue = Result<string[], FlowyError>;
export type ReorderSingleRowNotifyValue = Result<ReorderSingleRowPB, FlowyError>;

export class DatabaseViewRowsObserver {
  private _rowsVisibilityNotifier = new ChangeNotifier<RowsVisibilityNotifyValue>();
  private _rowsNotifier = new ChangeNotifier<RowsNotifyValue>();
  private _reorderRowsNotifier = new ChangeNotifier<ReorderRowsNotifyValue>();
  private _reorderSingleRowNotifier = new ChangeNotifier<ReorderSingleRowNotifyValue>();

  private _listener?: DatabaseNotificationObserver;

  constructor(public readonly viewId: string) {}

  subscribe = (callbacks: {
    onRowsVisibilityChanged?: (value: RowsVisibilityNotifyValue) => void;
    onNumberOfRowsChanged?: (value: RowsNotifyValue) => void;
    onReorderRows?: (value: ReorderRowsNotifyValue) => void;
    onReorderSingleRow?: (value: ReorderSingleRowNotifyValue) => void;
  }) => {
    //
    this._rowsVisibilityNotifier.observer.subscribe(callbacks.onRowsVisibilityChanged);
    this._rowsNotifier.observer.subscribe(callbacks.onNumberOfRowsChanged);
    this._reorderRowsNotifier.observer.subscribe(callbacks.onReorderRows);
    this._reorderSingleRowNotifier.observer.subscribe(callbacks.onReorderSingleRow);

    this._listener = new DatabaseNotificationObserver({
      viewId: this.viewId,
      parserHandler: (notification, result) => {
        switch (notification) {
          case DatabaseNotification.DidUpdateViewRowsVisibility:
            if (result.ok) {
              this._rowsVisibilityNotifier.notify(Ok(RowsVisibilityChangesetPB.deserializeBinary(result.val)));
            } else {
              this._rowsVisibilityNotifier.notify(result);
            }
            break;
          case DatabaseNotification.DidUpdateViewRows:
            if (result.ok) {
              this._rowsNotifier.notify(Ok(RowsChangesetPB.deserializeBinary(result.val)));
            } else {
              this._rowsNotifier.notify(result);
            }
            break;
          case DatabaseNotification.DidReorderRows:
            if (result.ok) {
              this._reorderRowsNotifier.notify(Ok(ReorderAllRowsPB.deserializeBinary(result.val).row_orders));
            } else {
              this._reorderRowsNotifier.notify(result);
            }
            break;
          case DatabaseNotification.DidReorderSingleRow:
            if (result.ok) {
              this._reorderSingleRowNotifier.notify(Ok(ReorderSingleRowPB.deserializeBinary(result.val)));
            } else {
              this._reorderSingleRowNotifier.notify(result);
            }
            break;
          default:
            break;
        }
      },
    });
  };

  unsubscribe = async () => {
    this._rowsVisibilityNotifier.unsubscribe();
    this._reorderRowsNotifier.unsubscribe();
    this._rowsNotifier.unsubscribe();
    this._reorderSingleRowNotifier.unsubscribe();
    await this._listener?.stop();
  };
}
