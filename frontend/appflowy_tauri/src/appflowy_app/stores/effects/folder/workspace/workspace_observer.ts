import { Ok, Result } from 'ts-results';
import { AppPB, FolderNotification, RepeatedAppPB, WorkspacePB, FlowyError } from '@/services/backend';
import { ChangeNotifier } from '$app/utils/change_notifier';
import { FolderNotificationObserver } from '../notifications/observer';

export type AppListNotifyValue = Result<AppPB[], FlowyError>;
export type AppListNotifyCallback = (value: AppListNotifyValue) => void;
export type WorkspaceNotifyValue = Result<WorkspacePB, FlowyError>;
export type WorkspaceNotifyCallback = (value: WorkspaceNotifyValue) => void;

export class WorkspaceObserver {
  private appListNotifier = new ChangeNotifier<AppListNotifyValue>();
  private workspaceNotifier = new ChangeNotifier<WorkspaceNotifyValue>();
  private listener?: FolderNotificationObserver;

  constructor(public readonly workspaceId: string) {}

  subscribe = async (callbacks: {
    onAppListChanged: AppListNotifyCallback;
    onWorkspaceChanged: WorkspaceNotifyCallback;
  }) => {
    this.appListNotifier?.observer.subscribe(callbacks.onAppListChanged);
    this.workspaceNotifier?.observer.subscribe(callbacks.onWorkspaceChanged);

    this.listener = new FolderNotificationObserver({
      viewId: this.workspaceId,
      parserHandler: (notification, result) => {
        switch (notification) {
          case FolderNotification.DidUpdateWorkspace:
            if (result.ok) {
              this.workspaceNotifier?.notify(Ok(WorkspacePB.deserializeBinary(result.val)));
            } else {
              this.workspaceNotifier?.notify(result);
            }
            break;
          case FolderNotification.DidUpdateWorkspaceApps:
            if (result.ok) {
              this.appListNotifier?.notify(Ok(RepeatedAppPB.deserializeBinary(result.val).items));
            } else {
              this.appListNotifier?.notify(result);
            }
            break;
          default:
            break;
        }
      },
    });
    await this.listener.start();
  };

  unsubscribe = async () => {
    this.appListNotifier.unsubscribe();
    this.workspaceNotifier.unsubscribe();
    await this.listener?.stop();
  };
}
