import { UserService } from '@/application/services/services.type';
import { UserProfile } from '@/application/user.type';
import { APIService } from 'src/application/services/js-services/wasm';
import { getSignInUser, setSignInUser } from '@/application/services/js-services/storage';
import { asyncDataDecorator } from '@/application/services/js-services/decorator';

export class JSUserService implements UserService {

  @asyncDataDecorator<void, UserProfile>(
    getSignInUser,
    setSignInUser,
    APIService.getUser,
  )
  async getUserProfile (): Promise<UserProfile> {
    console.log('getUserProfile');
    return null!;
  }

}
