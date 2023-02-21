import { Ok, Result } from 'ts-results';
import { FlowyError } from '../../../../../services/backend/models/flowy-error/errors';
import { DeletedViewPB, FolderNotification, ViewPB } from '../../../../../services/backend/models/flowy-folder';
import { ChangeNotifier } from '../../../../utils/change_notifier';
import { FolderNotificationObserver } from '../notifications/observer';

type DeleteViewNotifyValue = Result<ViewPB, FlowyError>;
type UpdateViewNotifyValue = Result<ViewPB, FlowyError>;
type RestoreViewNotifyValue = Result<ViewPB, FlowyError>;
type MoveToTrashViewNotifyValue = Result<DeletedViewPB, FlowyError>;

export class ViewObserver {
  _deleteViewNotifier = new ChangeNotifier<DeleteViewNotifyValue>();
  _updateViewNotifier = new ChangeNotifier<UpdateViewNotifyValue>();
  _restoreViewNotifier = new ChangeNotifier<RestoreViewNotifyValue>();
  _moveToTashNotifier = new ChangeNotifier<MoveToTrashViewNotifyValue>();
  _listener?: FolderNotificationObserver;

  constructor(public readonly viewId: string) {}

  subscribe = (callbacks: {
    onViewUpdate?: (value: UpdateViewNotifyValue) => void;
    onViewDelete?: (value: DeleteViewNotifyValue) => void;
    onViewRestored?: (value: RestoreViewNotifyValue) => void;
    onViewMoveToTrash?: (value: MoveToTrashViewNotifyValue) => void;
  }) => {
    if (callbacks.onViewDelete !== undefined) {
      this._deleteViewNotifier.observer.subscribe(callbacks.onViewDelete);
    }

    if (callbacks.onViewUpdate !== undefined) {
      this._updateViewNotifier.observer.subscribe(callbacks.onViewUpdate);
    }

    if (callbacks.onViewRestored !== undefined) {
      this._restoreViewNotifier.observer.subscribe(callbacks.onViewRestored);
    }

    if (callbacks.onViewMoveToTrash !== undefined) {
      this._moveToTashNotifier.observer.subscribe(callbacks.onViewMoveToTrash);
    }

    this._listener = new FolderNotificationObserver({
      viewId: this.viewId,
      parserHandler: (notification, payload) => {
        switch (notification) {
          case FolderNotification.DidUpdateView:
            this._updateViewNotifier.notify(Ok(ViewPB.deserializeBinary(payload)));
            break;
          case FolderNotification.DidDeleteView:
            this._deleteViewNotifier.notify(Ok(ViewPB.deserializeBinary(payload)));
            break;
          case FolderNotification.DidRestoreView:
            this._restoreViewNotifier.notify(Ok(ViewPB.deserializeBinary(payload)));
            break;
          case FolderNotification.DidMoveViewToTrash:
            this._moveToTashNotifier.notify(Ok(DeletedViewPB.deserializeBinary(payload)));
            break;
          default:
            break;
        }
      },
    });
    return undefined;
  };

  unsubscribe = async () => {
    this._deleteViewNotifier.unsubscribe();
    this._updateViewNotifier.unsubscribe();
    this._restoreViewNotifier.unsubscribe();
    this._moveToTashNotifier.unsubscribe();
    await this._listener?.stop();
  };
}
