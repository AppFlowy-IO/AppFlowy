import { UserService } from '@/application/services/services.type';
import { UserProfile } from '@/application/user.type';
import { notify } from '@/components/_shared/notify';
import { APIService } from 'src/application/services/js-services/wasm';
import { getAuthInfo, getSignInUser, setSignInUser } from '@/application/services/js-services/storage';
import { asyncDataDecorator } from '@/application/services/js-services/decorator';

async function getUser() {
  try {
    const user = await APIService.getUser();

    return user;
  } catch (e) {
    console.error(e);
    notify.error('Failed to get user profile, please try refreshing the page');
    // invalidToken();
  }
}

export class JSUserService implements UserService {
  @asyncDataDecorator<void, UserProfile>(getSignInUser, setSignInUser, getUser)
  async getUserProfile(): Promise<UserProfile> {
    if (!getAuthInfo()) {
      return Promise.reject('Not authenticated');
    }

    return null!;
  }

  async checkUser(): Promise<boolean> {
    return (await getSignInUser()) !== undefined;
  }
}
