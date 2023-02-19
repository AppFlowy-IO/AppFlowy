import { Ok, Result } from 'ts-results';
import { AppPB, FolderNotification } from '../../../../../services/backend';
import { FlowyError } from '../../../../../services/backend/models/flowy-error';
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
      parserHandler: (notification, payload) => {
        switch (notification) {
          case FolderNotification.DidUpdateWorkspaceApps:
            this._appNotifier?.notify(Ok(AppPB.deserializeBinary(payload)));
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
