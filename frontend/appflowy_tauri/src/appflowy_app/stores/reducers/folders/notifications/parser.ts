import { FolderNotification } from '../../../../../services/backend';
import { NotificationParser, OnNotificationError } from '../../../../../services/backend/notifications';

declare type FolderNotificationCallback = (ty: FolderNotification, payload: Uint8Array) => void;

export class FolderNotificationParser extends NotificationParser<FolderNotification> {
  constructor(params: { id?: string; callback: FolderNotificationCallback; onError?: OnNotificationError }) {
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
      params.id,
      params.onError
    );
  }
}

const isFolderNotification = (notification: string): notification is keyof typeof FolderNotification => {
  return Object.values(FolderNotification).indexOf(notification) !== -1;
};
