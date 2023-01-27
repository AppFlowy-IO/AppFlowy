import { Result } from "ts-results/result";
import { UserNotification, FlowyError } from "../../../../../services/backend";
import { NotificationParser, OnNotificationError } from "../../../../../services/backend/notifications/parser";

declare type UserNotificationCallback = (ty: UserNotification, payload: Uint8Array) => void;

export class UserNotificationParser extends NotificationParser<UserNotification> {
  constructor(callback: UserNotificationCallback, id?: String, onError?: OnNotificationError) {
    super(
      callback,
      (ty) => {
        let notification = UserNotification[ty];
        if (isUserNotification(notification)) {
          return UserNotification[notification];
        } else {
          return UserNotification.Unknown;
        }
      },
      id,
      onError
    );
  }
}

const isUserNotification = (notification: string): notification is keyof typeof UserNotification => {
  return Object.values(UserNotification).indexOf(notification) !== -1;
};
