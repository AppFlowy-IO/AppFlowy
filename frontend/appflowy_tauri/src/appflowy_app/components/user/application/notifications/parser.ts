import { UserNotification } from '../../../../../services/backend';
import { NotificationParser, OnNotificationError } from '../../../../../services/backend/notifications/parser';

declare type UserNotificationCallback = (ty: UserNotification, payload: Uint8Array) => void;

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
      params.id,
      params.onError
    );
  }
}

const isUserNotification = (notification: string): notification is keyof typeof UserNotification => {
  return Object.values(UserNotification).indexOf(notification) !== -1;
};
