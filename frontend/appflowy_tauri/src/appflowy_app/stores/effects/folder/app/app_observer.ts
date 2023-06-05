import { FolderNotification } from '@/services/backend';
import { ChangeNotifier } from '$app/utils/change_notifier';
import { FolderNotificationObserver } from '../notifications/observer';

export class AppObserver {
  _viewsNotifier = new ChangeNotifier<void>();
  _listener?: FolderNotificationObserver;

  constructor(public readonly appId: string) {}

  subscribe = async (callbacks: { onViewsChanged: () => void }) => {
    this._viewsNotifier?.observer?.subscribe(callbacks.onViewsChanged);
    this._listener = new FolderNotificationObserver({
      viewId: this.appId,
      parserHandler: (notification, result) => {
        switch (notification) {
          case FolderNotification.DidUpdateChildViews:
            if (result.ok) {
              this._viewsNotifier?.notify();
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
    this._viewsNotifier.unsubscribe();
    await this._listener?.stop();
  };
}
