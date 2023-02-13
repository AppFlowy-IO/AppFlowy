import { UserNotification, UserProfilePB } from '../../../../../services/backend';
import { AFNotificationListener, OnNotificationError } from '../../../../../services/backend/notifications';
import { UserNotificationParser } from './parser';

declare type OnUserProfileUpdate = (userProfile: UserProfilePB) => void;
declare type OnUserSignIn = (userProfile: UserProfilePB) => void;

export class UserNotificationListener extends AFNotificationListener<UserNotification> {
  onProfileUpdate?: OnUserProfileUpdate;
  onUserSignIn?: OnUserSignIn;

  constructor(params: {
    userId?: string;
    onUserSignIn?: OnUserSignIn;
    onProfileUpdate?: OnUserProfileUpdate;
    onError?: OnNotificationError;
  }) {
    const parser = new UserNotificationParser({
      callback: (notification, payload) => {
        switch (notification) {
          case UserNotification.DidUpdateUserProfile:
            this.onProfileUpdate?.(UserProfilePB.deserializeBinary(payload));
            break;
          case UserNotification.DidUserSignIn:
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
