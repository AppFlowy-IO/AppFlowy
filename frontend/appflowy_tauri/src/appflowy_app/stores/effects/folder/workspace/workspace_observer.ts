import { Ok, Result } from 'ts-results';
import { AppPB, FolderNotification, RepeatedAppPB, WorkspacePB, FlowyError } from '../../../../../services/backend';
import { ChangeNotifier } from '../../../../utils/change_notifier';
import { FolderNotificationObserver } from '../notifications/observer';

export type AppListNotifyValue = Result<AppPB[], FlowyError>;
export type AppListNotifyCallback = (value: AppListNotifyValue) => void;
export type WorkspaceNotifyValue = Result<WorkspacePB, FlowyError>;
export type WorkspaceNotifyCallback = (value: WorkspaceNotifyValue) => void;

export class WorkspaceObserver {
  private _appListNotifier = new ChangeNotifier<AppListNotifyValue>();
  private _workspaceNotifier = new ChangeNotifier<WorkspaceNotifyValue>();
  private _listener?: FolderNotificationObserver;

  constructor(public readonly workspaceId: string) {}

  subscribe = (callbacks: { onAppListChanged: AppListNotifyCallback; onWorkspaceChanged: WorkspaceNotifyCallback }) => {
    this._appListNotifier?.observer.subscribe(callbacks.onAppListChanged);
    this._workspaceNotifier?.observer.subscribe(callbacks.onWorkspaceChanged);

    this._listener = new FolderNotificationObserver({
      viewId: this.workspaceId,
      parserHandler: (notification, result) => {
        switch (notification) {
          case FolderNotification.DidUpdateWorkspace:
            if (result.ok) {
              this._workspaceNotifier?.notify(Ok(WorkspacePB.deserializeBinary(result.val)));
            } else {
              this._workspaceNotifier?.notify(result);
            }
            break;
          case FolderNotification.DidUpdateWorkspaceApps:
            if (result.ok) {
              this._appListNotifier?.notify(Ok(RepeatedAppPB.deserializeBinary(result.val).items));
            } else {
              this._appListNotifier?.notify(result);
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
    this._appListNotifier.unsubscribe();
    this._workspaceNotifier.unsubscribe();
    await this._listener?.stop();
  };
}
