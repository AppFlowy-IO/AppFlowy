import { AuthService } from '@/application/services/services.type';
import { ProviderType, SignUpWithEmailPasswordParams } from '@/application/user.type';
import { APIService } from 'src/application/services/js-services/wasm';
import { signInSuccess } from '@/application/services/js-services/session/auth';
import { invalidToken } from 'src/application/services/js-services/session';
import { afterSignInDecorator } from '@/application/services/js-services/decorator';

export class JSAuthService implements AuthService {
  constructor() {
    // Do nothing
  }

  getOAuthURL = async (_provider: ProviderType): Promise<string> => {
    return Promise.reject('Not implemented');
  };

  @afterSignInDecorator(signInSuccess)
  async signInWithOAuth(_: { uri: string }): Promise<void> {
    return Promise.reject('Not implemented');
  }

  signupWithEmailPassword = async (_params: SignUpWithEmailPasswordParams): Promise<void> => {
    return Promise.reject('Not implemented');
  };

  @afterSignInDecorator(signInSuccess)
  async signinWithEmailPassword(email: string, password: string): Promise<void> {
    try {
      return APIService.signIn(email, password);
    } catch (e) {
      return Promise.reject(e);
    }
  }

  signOut = async (): Promise<void> => {
    invalidToken();
    return APIService.logout();
  };
}
