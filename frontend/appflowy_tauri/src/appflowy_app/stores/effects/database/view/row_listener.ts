import { Ok, Result } from 'ts-results';
import {
  DatabaseNotification,
  ReorderAllRowsPB,
  ReorderSingleRowPB,
} from '../../../../../services/backend/events/flowy-database';
import {
  ViewRowsChangesetPB,
  ViewRowsVisibilityChangesetPB,
} from '../../../../../services/backend/models/flowy-database/view_entities';
import { FlowyError } from '../../../../../services/backend/models/flowy-error/errors';
import { ChangeNotifier } from '../../../../utils/change_notifier';
import { DatabaseNotificationListener } from '../../notifications/listener';

export type RowsVisibilityNotifyValue = Result<ViewRowsVisibilityChangesetPB, FlowyError>;
export type RowsNotifyValue = Result<ViewRowsChangesetPB, FlowyError>;
export type ReorderRowsNotifyValue = Result<string[], FlowyError>;
export type ReorderSingleRowNotifyValue = Result<ReorderSingleRowPB, FlowyError>;

export class DatabaseViewRowsListener {
  _rowsVisibilityNotifier = new ChangeNotifier<RowsVisibilityNotifyValue>();
  _rowsNotifier = new ChangeNotifier<RowsNotifyValue>();
  _reorderRowsNotifier = new ChangeNotifier<ReorderRowsNotifyValue>();
  _reorderSingleRowNotifier = new ChangeNotifier<ReorderSingleRowNotifyValue>();

  _listener?: DatabaseNotificationListener;
  constructor(public readonly viewId: string) {}

  start = (callbacks: {
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

    this._listener = new DatabaseNotificationListener({
      viewId: this.viewId,
      parserHandler: (notification, payload) => {
        switch (notification) {
          case DatabaseNotification.DidUpdateViewRowsVisibility:
            this._rowsVisibilityNotifier.notify(Ok(ViewRowsVisibilityChangesetPB.deserializeBinary(payload)));
            break;
          case DatabaseNotification.DidUpdateViewRows:
            this._rowsNotifier.notify(Ok(ViewRowsChangesetPB.deserializeBinary(payload)));
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

  stop = async () => {
    this._rowsVisibilityNotifier.unsubscribe();
    this._reorderRowsNotifier.unsubscribe();
    this._rowsNotifier.unsubscribe();
    this._reorderSingleRowNotifier.unsubscribe();
    await this._listener?.stop();
  };
}
