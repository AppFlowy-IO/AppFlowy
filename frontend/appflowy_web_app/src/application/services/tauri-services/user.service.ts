import { UserService } from '@/application/services/services.type';
import { UserProfile } from '@/application/services/user.type';
import { UserEventGetUserProfile } from './backend/events/flowy-user';
import { parseUserProfileFrom } from '@/application/services/tauri-services/auth.service';

export class TauriUserService implements UserService {
  async getUserProfile (): Promise<UserProfile | null> {
    const res = await UserEventGetUserProfile();

    if (res.ok) {
      return parseUserProfileFrom(res.val);
    }

    return null;
  }
}