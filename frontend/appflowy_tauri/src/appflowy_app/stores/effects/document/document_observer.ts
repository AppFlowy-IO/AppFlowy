import { Ok, Result } from 'ts-results';
import { ChangeNotifier } from '$app/utils/change_notifier';
import { FolderNotificationObserver } from '../folder/notifications/observer';
import { DocumentNotification } from '@/services/backend';
import { DocumentNotificationObserver } from './notifications/observer';

export type DidReceiveUpdateCallback = (payload: Uint8Array) => void; // todo: add params

export class DocumentObserver {
  private listener?: DocumentNotificationObserver;

  constructor(public readonly workspaceId: string) {}

  subscribe = async (callbacks: { didReceiveUpdate: DidReceiveUpdateCallback }) => {
    this.listener = new DocumentNotificationObserver({
      viewId: this.workspaceId,
      parserHandler: (notification, result) => {
        switch (notification) {
          case DocumentNotification.DidReceiveUpdate:
            if (!result.ok) break;
            callbacks.didReceiveUpdate(result.val);

            break;
          default:
            break;
        }
      },
    });
    await this.listener.start();
  };

  unsubscribe = async () => {
    // this.appListNotifier.unsubscribe();
    // this.workspaceNotifier.unsubscribe();
    await this.listener?.stop();
  };
}
