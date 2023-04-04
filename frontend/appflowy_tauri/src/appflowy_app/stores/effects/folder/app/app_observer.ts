import { Ok, Result } from 'ts-results';
import { AppPB, FlowyError, FolderNotification } from '@/services/backend';
import { ChangeNotifier } from '$app/utils/change_notifier';
import { FolderNotificationObserver } from '../notifications/observer';

export type AppUpdateNotifyCallback = (value: Result<AppPB, FlowyError>) => void;

export class AppObserver {
  _appNotifier = new ChangeNotifier<Result<AppPB, FlowyError>>();
  _listener?: FolderNotificationObserver;

  constructor(public readonly appId: string) {}

  subscribe = async (callbacks: { onAppChanged: AppUpdateNotifyCallback }) => {
    this._appNotifier?.observer.subscribe(callbacks.onAppChanged);
    this._listener = new FolderNotificationObserver({
      viewId: this.appId,
      parserHandler: (notification, result) => {
        switch (notification) {
          case FolderNotification.DidUpdateWorkspaceApps:
            if (result.ok) {
              this._appNotifier?.notify(Ok(AppPB.deserializeBinary(result.val)));
            } else {
              this._appNotifier?.notify(result);
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
