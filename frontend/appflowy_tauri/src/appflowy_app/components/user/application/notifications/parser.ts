import { FlowyError, UserNotification } from '@/services/backend';
import { NotificationParser, OnNotificationError } from '@/services/backend/notifications';
import { Result } from 'ts-results';

declare type UserNotificationCallback = (ty: UserNotification, payload: Result<Uint8Array, FlowyError>) => void;

export class UserNotificationParser extends NotificationParser<UserNotification> {
  constructor(params: { id?: string; callback: UserNotificationCallback; onError?: OnNotificationError }) {
    super(
      params.callback,
      (ty) => {
        const notification = UserNotification[ty];
        if (isUserNotification(notification)) {
          return UserNotification[notification];
        } else {
          return UserNotification.Unknown;
        }
      },
      params.id
    );
  }
}

const isUserNotification = (notification: string): notification is keyof typeof UserNotification => {
  return Object.values(UserNotification).indexOf(notification) !== -1;
};
