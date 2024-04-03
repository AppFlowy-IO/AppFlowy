import { AFCloudConfig, AuthService } from '@/application/services/services.type';
import {
  AuthenticatorPB,
  OauthProviderPB,
  OauthSignInPB,
  SignInPayloadPB,
  SignUpPayloadPB,
  UserEventGetOauthURLWithProvider,
  UserEventOauthSignIn,
  UserEventSignInWithEmailPassword,
  UserEventSignOut,
  UserEventSignUp,
  UserProfilePB,
} from './backend/events/flowy-user';
import { ProviderType, SignUpWithEmailPasswordParams, UserProfile } from '@/application/services/user.type';

export class TauriAuthService implements AuthService {

  constructor (private cloudConfig: AFCloudConfig, private clientConfig: {
    deviceId: string;
    clientId: string;

  }) {}

  getDeviceID = (): string => {
    return this.clientConfig.deviceId;
  };
  getOAuthURL = async (provider: ProviderType): Promise<string> => {
    const providerDataRes = await UserEventGetOauthURLWithProvider(
      OauthProviderPB.fromObject({
        provider: provider as number,
      }),
    );

    if (!providerDataRes.ok) {
      throw new Error(providerDataRes.val.msg);
    }

    const providerData = providerDataRes.val;

    return providerData.oauth_url;
  };

  signInWithOAuth = async ({ uri }: { uri: string }): Promise<UserProfile> => {
    const payload = OauthSignInPB.fromObject({
      authenticator: AuthenticatorPB.AppFlowyCloud,
      map: {
        sign_in_url: uri,
        device_id: this.getDeviceID(),
      },
    });

    const res = await UserEventOauthSignIn(payload);

    if (!res.ok) {
      throw new Error(res.val.msg);
    }

    return parseUserProfileFrom(res.val);
  };
  signinWithEmailPassword = async (email: string, password: string): Promise<UserProfile> => {
    const payload = SignInPayloadPB.fromObject({
      email,
      password,
    });

    const res = await UserEventSignInWithEmailPassword(payload);

    if (!res.ok) {
      return Promise.reject(res.val.msg);
    }

    return parseUserProfileFrom(res.val);
  };

  signupWithEmailPassword = async (params: SignUpWithEmailPasswordParams): Promise<UserProfile> => {
    const payload = SignUpPayloadPB.fromObject({
      name: params.name,
      email: params.email,
      password: params.password,
      device_id: this.getDeviceID(),
    });

    const res = await UserEventSignUp(payload);

    if (!res.ok) {
      console.error(res.val.msg);
      return Promise.reject(res.val.msg);
    }

    return parseUserProfileFrom(res.val);
  };

  signOut = async () => {
    const res = await UserEventSignOut();

    if (!res.ok) {
      return Promise.reject(res.val.msg);
    }

    return;
  };
}

export function parseUserProfileFrom (userPB: UserProfilePB): UserProfile {
  const user = userPB.toObject();

  return {
    id: String(user.id),
    email: user.email,
    name: user.name,
    token: user.token,
    iconUrl: user.icon_url,
    openaiKey: user.openai_key,
    authenticator: user.authenticator as number,
    encryptionSign: user.encryption_sign,
    encryptionType: user.encryption_type as number,
    workspaceId: user.workspace_id,
    stabilityAiKey: user.stability_ai_key,
  };
}
