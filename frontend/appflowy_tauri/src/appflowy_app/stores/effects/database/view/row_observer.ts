import { Ok, Result } from 'ts-results';
import {
  DatabaseNotification,
  ReorderAllRowsPB,
  ReorderSingleRowPB,
} from '../../../../../services/backend/events/flowy-database';
import {
  RowsChangesetPB,
  RowsVisibilityChangesetPB,
} from '../../../../../services/backend/models/flowy-database/view_entities';
import { FlowyError } from '../../../../../services/backend/models/flowy-error/errors';
import { ChangeNotifier } from '../../../../utils/change_notifier';
import { DatabaseNotificationObserver } from '../notifications/observer';

export type RowsVisibilityNotifyValue = Result<RowsVisibilityChangesetPB, FlowyError>;
export type RowsNotifyValue = Result<RowsChangesetPB, FlowyError>;
export type ReorderRowsNotifyValue = Result<string[], FlowyError>;
export type ReorderSingleRowNotifyValue = Result<ReorderSingleRowPB, FlowyError>;

export class DatabaseViewRowsObserver {
  _rowsVisibilityNotifier = new ChangeNotifier<RowsVisibilityNotifyValue>();
  _rowsNotifier = new ChangeNotifier<RowsNotifyValue>();
  _reorderRowsNotifier = new ChangeNotifier<ReorderRowsNotifyValue>();
  _reorderSingleRowNotifier = new ChangeNotifier<ReorderSingleRowNotifyValue>();

  _listener?: DatabaseNotificationObserver;
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
      parserHandler: (notification, payload) => {
        switch (notification) {
          case DatabaseNotification.DidUpdateViewRowsVisibility:
            this._rowsVisibilityNotifier.notify(Ok(RowsVisibilityChangesetPB.deserializeBinary(payload)));
            break;
          case DatabaseNotification.DidUpdateViewRows:
            this._rowsNotifier.notify(Ok(RowsChangesetPB.deserializeBinary(payload)));
            break;
          case DatabaseNotification.DidReorderRows:
            this._reorderRowsNotifier.notify(Ok(ReorderAllRowsPB.deserializeBinary(payload).row_orders));
            break;
          case DatabaseNotification.DidReorderSingleRow:
            this._reorderSingleRowNotifier.notify(Ok(ReorderSingleRowPB.deserializeBinary(payload)));
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
