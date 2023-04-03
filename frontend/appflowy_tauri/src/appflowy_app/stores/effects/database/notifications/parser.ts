import { DatabaseNotification, FlowyError } from '@/services/backend';
import { NotificationParser } from '@/services/backend/notifications';
import { Result } from 'ts-results';

declare type DatabaseNotificationCallback = (ty: DatabaseNotification, payload: Result<Uint8Array, FlowyError>) => void;

export class DatabaseNotificationParser extends NotificationParser<DatabaseNotification> {
  constructor(params: { id?: string; callback: DatabaseNotificationCallback }) {
    super(
      params.callback,
      (ty) => {
        const notification = DatabaseNotification[ty];
        if (isDatabaseNotification(notification)) {
          return DatabaseNotification[notification];
        } else {
          return DatabaseNotification.Unknown;
        }
      },
      params.id
    );
  }
}

const isDatabaseNotification = (notification: string): notification is keyof typeof DatabaseNotification => {
  return Object.values(DatabaseNotification).indexOf(notification) !== -1;
};
