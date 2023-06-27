import { Ok, Result } from 'ts-results';
import { DeletedViewPB, FolderNotification, ViewPB, FlowyError } from '@/services/backend';
import { ChangeNotifier } from '$app/utils/change_notifier';
import { FolderNotificationObserver } from '../notifications/observer';

type DeleteViewNotifyValue = Result<ViewPB, FlowyError>;
type UpdateViewNotifyValue = Result<ViewPB, FlowyError>;
type RestoreViewNotifyValue = Result<ViewPB, FlowyError>;
type MoveToTrashViewNotifyValue = Result<DeletedViewPB, FlowyError>;

export class ViewObserver {
  private _deleteViewNotifier = new ChangeNotifier<DeleteViewNotifyValue>();
  private _updateViewNotifier = new ChangeNotifier<UpdateViewNotifyValue>();
  private _restoreViewNotifier = new ChangeNotifier<RestoreViewNotifyValue>();
  private _moveToTrashNotifier = new ChangeNotifier<MoveToTrashViewNotifyValue>();
  private _childViewsNotifier = new ChangeNotifier<void>();
  private _listener?: FolderNotificationObserver;

  constructor(public readonly viewId: string) {}

  subscribe = async (callbacks: {
    onViewUpdate?: (value: UpdateViewNotifyValue) => void;
    onViewDelete?: (value: DeleteViewNotifyValue) => void;
    onViewRestored?: (value: RestoreViewNotifyValue) => void;
    onViewMoveToTrash?: (value: MoveToTrashViewNotifyValue) => void;
    onChildViewsChanged?: () => void;
  }) => {
    if (callbacks.onViewDelete !== undefined) {
      this._deleteViewNotifier.observer?.subscribe(callbacks.onViewDelete);
    }

    if (callbacks.onViewUpdate !== undefined) {
      this._updateViewNotifier.observer?.subscribe(callbacks.onViewUpdate);
    }

    if (callbacks.onViewRestored !== undefined) {
      this._restoreViewNotifier.observer?.subscribe(callbacks.onViewRestored);
    }

    if (callbacks.onViewMoveToTrash !== undefined) {
      this._moveToTrashNotifier.observer?.subscribe(callbacks.onViewMoveToTrash);
    }

    if (callbacks.onChildViewsChanged !== undefined) {
      this._childViewsNotifier.observer?.subscribe(callbacks.onChildViewsChanged);
    }

    this._listener = new FolderNotificationObserver({
      viewId: this.viewId,
      parserHandler: (notification, result) => {
        switch (notification) {
          case FolderNotification.DidUpdateView:
            if (result.ok) {
              this._updateViewNotifier.notify(Ok(ViewPB.deserializeBinary(result.val)));
            } else {
              this._updateViewNotifier.notify(result);
            }
            break;
          case FolderNotification.DidDeleteView:
            if (result.ok) {
              this._deleteViewNotifier.notify(Ok(ViewPB.deserializeBinary(result.val)));
            } else {
              this._deleteViewNotifier.notify(result);
            }
            break;
          case FolderNotification.DidRestoreView:
            if (result.ok) {
              this._restoreViewNotifier.notify(Ok(ViewPB.deserializeBinary(result.val)));
            } else {
              this._restoreViewNotifier.notify(result);
            }
            break;
          case FolderNotification.DidMoveViewToTrash:
            if (result.ok) {
              this._moveToTrashNotifier.notify(Ok(DeletedViewPB.deserializeBinary(result.val)));
            } else {
              this._moveToTrashNotifier.notify(result);
            }
            break;
          case FolderNotification.DidUpdateChildViews:
            if (result.ok) {
              this._childViewsNotifier?.notify();
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
    this._deleteViewNotifier.unsubscribe();
    this._updateViewNotifier.unsubscribe();
    this._restoreViewNotifier.unsubscribe();
    this._moveToTrashNotifier.unsubscribe();
    this._childViewsNotifier.unsubscribe();
    await this._listener?.stop();
  };
}
