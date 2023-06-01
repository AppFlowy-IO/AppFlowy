import { Ok, Result } from 'ts-results';
import { FlowyError, FolderNotification, RepeatedViewPB } from '@/services/backend';
import { ChangeNotifier } from '$app/utils/change_notifier';
import { FolderNotificationObserver } from '../notifications/observer';

export type AppUpdateNotifyCallback = (value: Result<RepeatedViewPB, FlowyError>) => void;

export class AppObserver {
  _appNotifier = new ChangeNotifier<Result<RepeatedViewPB, FlowyError>>();
  _viewsNotifier = new ChangeNotifier<void>();
  _listener?: FolderNotificationObserver;

  constructor(public readonly appId: string) {}

  subscribe = async (callbacks: { onAppChanged: AppUpdateNotifyCallback; onViewsChanged: () => void }) => {
    this._appNotifier?.observer?.subscribe(callbacks.onAppChanged);
    this._viewsNotifier?.observer?.subscribe(callbacks.onViewsChanged);
    this._listener = new FolderNotificationObserver({
      viewId: this.appId,
      parserHandler: (notification, result) => {
        console.log('AppObserver: notification', notification, result);
        switch (notification) {
          case FolderNotification.DidUpdateWorkspaceViews:
            if (result.ok) {
              this._appNotifier?.notify(Ok(RepeatedViewPB.deserializeBinary(result.val)));
            } else {
              this._appNotifier?.notify(result);
            }
            break;

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
    this._appNotifier.unsubscribe();
    await this._listener?.stop();
  };
}
