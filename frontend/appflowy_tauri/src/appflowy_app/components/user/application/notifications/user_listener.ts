import { FlowyError, UserNotification, UserProfilePB } from '@/services/backend';
import { AFNotificationObserver, OnNotificationError } from '@/services/backend/notifications';
import { UserNotificationParser } from './parser';
import { Ok, Result } from 'ts-results';

declare type OnUserProfileUpdate = (result: Result<UserProfilePB, FlowyError>) => void;
declare type OnUserSignIn = (result: Result<UserProfilePB, FlowyError>) => void;

export class UserNotificationListener extends AFNotificationObserver<UserNotification> {
  onProfileUpdate?: OnUserProfileUpdate;
  onUserSignIn?: OnUserSignIn;

  constructor(params: {
    userId?: string;
    onUserSignIn?: OnUserSignIn;
    onProfileUpdate?: OnUserProfileUpdate;
    onError?: OnNotificationError;
  }) {
    const parser = new UserNotificationParser({
      callback: (notification, result) => {
        switch (notification) {
          case UserNotification.DidUpdateUserProfile:
            if (result.ok) {
              this.onProfileUpdate?.(Ok(UserProfilePB.deserializeBinary(result.val)));
            } else {
              this.onProfileUpdate?.(result);
            }
            break;
          case UserNotification.DidUserSignIn:
            if (result.ok) {
              this.onUserSignIn?.(Ok(UserProfilePB.deserializeBinary(result.val)));
            } else {
              this.onUserSignIn?.(result);
            }
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
