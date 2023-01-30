import { FlowyError, UserNotification, UserProfilePB } from '../../../../../services/backend';
import { AFNotificationListener, OnNotificationError } from '../../../../../services/backend/notifications';
import { UserNotificationParser } from './parser';

declare type OnUserProfileUpdate = (userProfile: UserProfilePB) => void;
declare type OnUserSignIn = (userProfile: UserProfilePB) => void;

export class UserNotificationListener extends AFNotificationListener<UserNotification> {
  onProfileUpdate?: OnUserProfileUpdate;
  onUserSignIn?: OnUserSignIn;

  constructor(params: {
    userId?: String;
    onUserSignIn?: OnUserSignIn;
    onProfileUpdate?: OnUserProfileUpdate;
    onError?: OnNotificationError;
  }) {
    let parser = new UserNotificationParser({
      callback: (notification, payload) => {
        switch (notification) {
          case UserNotification.UserAuthChanged:
            break;
          case UserNotification.UserProfileUpdated:
            this.onProfileUpdate?.(UserProfilePB.deserializeBinary(payload));
            break;
          case UserNotification.UserUnauthorized:
            break;
          case UserNotification.UserSignIn:
            this.onUserSignIn?.(UserProfilePB.deserializeBinary(payload));
            break;
          default:
            break;
        }
      },
      id: params.userId,
      onError: params.onError,
    });
    super(parser);
    this.onProfileUpdate = params.onProfileUpdate;
    this.onUserSignIn = params.onUserSignIn;
  }
}
