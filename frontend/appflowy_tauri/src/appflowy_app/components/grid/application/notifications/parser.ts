import { DatabaseNotification } from "../../../../../services/backend";
import { NotificationParser, OnNotificationError } from "../../../../../services/backend/notifications/parser";

declare type DatabaseNotificationCallback = (ty: DatabaseNotification, payload: Uint8Array) => void;

export class DatabaseNotificationParser extends NotificationParser<DatabaseNotification> {
  constructor(params: { id?: String; callback: DatabaseNotificationCallback; onError?: OnNotificationError }) {
    super(
      params.callback,
      (ty) => {
        let notification = DatabaseNotification[ty];
        if (isDatabaseNotification(notification)) {
          return DatabaseNotification[notification];
        } else {
          return DatabaseNotification.Unknown;
        }
      },
      params.id,
      params.onError
    );
  }
}

const isDatabaseNotification = (notification: string): notification is keyof typeof DatabaseNotification => {
  return Object.values(DatabaseNotification).indexOf(notification) !== -1;
};
