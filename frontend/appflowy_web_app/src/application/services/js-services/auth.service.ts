import { AuthService } from '@/application/services/services.type';
import { ProviderType, SignUpWithEmailPasswordParams, UserProfile } from '@/application/services/user.type';
import { HttpClient } from '@/application/services/js-services/http/client';
import { ACCESS_TOKEN_NAME, REFRESH_TOKEN_NAME, TOKEN_TYPE_NAME } from '@/application/services/js-services/http/const';
import { AFWasmService } from '@/application/services/wasm-services';

export class JSAuthService implements AuthService {

  constructor (private httpClient: HttpClient, private wasmService: AFWasmService) {
    // Do nothing
  }

  getOAuthURL = async (_provider: ProviderType): Promise<string> => {
    return Promise.reject('Not implemented');
  };

  signInWithOAuth = async ({ uri }: { uri: string }): Promise<UserProfile> => {
    const params = uri.split('#')[1].split('&');
    const data: Record<string, string> = {};

    params.forEach((param) => {
      const [key, value] = param.split('=');

      data[key] = value;
    });

    sessionStorage.setItem(TOKEN_TYPE_NAME, data.token_type);
    sessionStorage.setItem(ACCESS_TOKEN_NAME, data.access_token);
    sessionStorage.setItem(REFRESH_TOKEN_NAME, data.refresh_token);
    return this.httpClient.getUser();
  };
  signupWithEmailPassword = async (_params: SignUpWithEmailPasswordParams): Promise<UserProfile> => {
    return Promise.reject('Not implemented');
  };

  signinWithEmailPassword = async (email: string, password: string): Promise<UserProfile> => {
    // await this.wasmService.cloudService.signIn(email, password);
    // return Promise.reject('Not implemented');
    return this.httpClient.signInWithEmailPassword(email, password);
  };

  signOut = async (): Promise<void> => {
    return this.httpClient.logout();
  };
}
