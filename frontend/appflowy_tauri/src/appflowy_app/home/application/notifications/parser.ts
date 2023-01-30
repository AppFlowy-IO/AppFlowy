import { FolderNotification } from '../../../../services/backend';
import { NotificationParser, OnNotificationError } from '../../../../services/backend/notifications/parser';

declare type FolderNotificationCallback = (ty: FolderNotification, payload: Uint8Array) => void;

export class FolderNotificationParser extends NotificationParser<FolderNotification> {
  constructor(params: { id?: String; callback: FolderNotificationCallback; onError?: OnNotificationError }) {
    super(
      params.callback,
      (ty) => {
        let notification = FolderNotification[ty];
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
