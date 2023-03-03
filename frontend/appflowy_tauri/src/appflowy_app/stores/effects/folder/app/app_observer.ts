import { Ok, Result } from 'ts-results';
import { AppPB, FlowyError, FolderNotification } from '../../../../../services/backend';
import { ChangeNotifier } from '../../../../utils/change_notifier';
import { FolderNotificationObserver } from '../notifications/observer';

export type AppUpdateNotifyValue = Result<AppPB, FlowyError>;
export type AppUpdateNotifyCallback = (value: AppUpdateNotifyValue) => void;

export class WorkspaceObserver {
  _appNotifier = new ChangeNotifier<AppUpdateNotifyValue>();
  _listener?: FolderNotificationObserver;

  constructor(public readonly appId: string) {}

  subscribe = (callbacks: { onAppChanged: AppUpdateNotifyCallback }) => {
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
    return undefined;
  };

  unsubscribe = async () => {
    this._appNotifier.unsubscribe();
    await this._listener?.stop();
  };
}
