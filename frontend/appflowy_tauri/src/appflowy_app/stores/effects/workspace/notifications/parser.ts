import { NotificationParser, OnNotificationError } from '@/services/backend/notifications';
import { FlowyError, FolderNotification } from '@/services/backend';
import { Result } from 'ts-results';

declare type WorkspaceNotificationCallback = (ty: FolderNotification, payload: Result<Uint8Array, FlowyError>) => void;

export class WorkspaceNotificationParser extends NotificationParser<FolderNotification> {
  constructor(params: { id?: string; callback: WorkspaceNotificationCallback; onError?: OnNotificationError }) {
    super(
      params.callback,
      (ty) => {
        const notification = FolderNotification[ty];

        if (isFolderNotification(notification)) {
          return FolderNotification[notification];
        } else {
          return FolderNotification.Unknown;
        }
      },
      params.id
    );
  }
}

const isFolderNotification = (notification: string): notification is keyof typeof FolderNotification => {
  return Object.values(FolderNotification).indexOf(notification) !== -1;
};
