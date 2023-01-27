import { FlowyError, UserNotification, UserProfilePB } from "../../../../../services/backend";
import { AFNotificationListener, OnNotificationError } from "../../../../../services/backend/notifications";
import { UserNotificationParser } from "./parser";

declare type OnUserProfileUpdate = (userProfile: UserProfilePB) => void;

export class UserNotificationListener extends AFNotificationListener<UserNotification> {
  onProfileUpdate?: OnUserProfileUpdate;

  constructor(userId?: String, onProfileUpdate?: OnUserProfileUpdate, onError?: OnNotificationError) {
    let parser = new UserNotificationParser(
      (notification, payload) => {
        switch (notification) {
          case UserNotification.UserAuthChanged:
            break;
          case UserNotification.UserProfileUpdated:
            break;
          case UserNotification.UserUnauthorized:
            break;
          case UserNotification.UserSignIn:
            let userProfile = UserProfilePB.deserializeBinary(payload);
            this.onProfileUpdate?.(userProfile);
            break;
          default:
            break;
        }
      },
      userId,
      onError
    );
    super(parser);
    this.onProfileUpdate = onProfileUpdate;
  }
}
