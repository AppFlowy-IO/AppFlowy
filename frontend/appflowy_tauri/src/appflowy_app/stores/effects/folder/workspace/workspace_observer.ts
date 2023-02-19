import { Ok, Result } from 'ts-results';
import { AppPB, FolderNotification, RepeatedAppPB, WorkspacePB } from '../../../../../services/backend';
import { FlowyError } from '../../../../../services/backend/models/flowy-error';
import { ChangeNotifier } from '../../../../utils/change_notifier';
import { FolderNotificationObserver } from '../notifications/observer';

export type AppListNotifyValue = Result<AppPB[], FlowyError>;
export type AppListNotifyCallback = (value: AppListNotifyValue) => void;
export type WorkspaceNotifyValue = Result<WorkspacePB, FlowyError>;
export type WorkspaceNotifyCallback = (value: WorkspaceNotifyValue) => void;

export class WorkspaceObserver {
  _appListNotifier = new ChangeNotifier<AppListNotifyValue>();
  _workspaceNotifier = new ChangeNotifier<WorkspaceNotifyValue>();
  _listener?: FolderNotificationObserver;

  constructor(public readonly workspaceId: string) {}

  subscribe = (callbacks: { onAppListChanged: AppListNotifyCallback; onWorkspaceChanged: WorkspaceNotifyCallback }) => {
    this._appListNotifier?.observer.subscribe(callbacks.onAppListChanged);
    this._workspaceNotifier?.observer.subscribe(callbacks.onWorkspaceChanged);

    this._listener = new FolderNotificationObserver({
      viewId: this.workspaceId,
      parserHandler: (notification, payload) => {
        switch (notification) {
          case FolderNotification.DidUpdateWorkspace:
            this._workspaceNotifier?.notify(Ok(WorkspacePB.deserializeBinary(payload)));
            break;
          case FolderNotification.DidUpdateWorkspaceApps:
            this._appListNotifier?.notify(Ok(RepeatedAppPB.deserializeBinary(payload).items));
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
