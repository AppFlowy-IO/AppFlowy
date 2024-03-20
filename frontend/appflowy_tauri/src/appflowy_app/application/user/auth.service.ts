import {
  SignUpPayloadPB,
  OauthProviderPB,
  ProviderTypePB,
  OauthSignInPB,
  AuthenticatorPB,
  SignInPayloadPB,
} from '@/services/backend';
import {
  UserEventSignOut,
  UserEventSignUp,
  UserEventGetOauthURLWithProvider,
  UserEventOauthSignIn,
  UserEventSignInWithEmailPassword,
} from '@/services/backend/events/flowy-user';
import { Log } from '$app/utils/log';

export const AuthService = {
  getOAuthURL: async (provider: ProviderTypePB) => {
    const providerDataRes = await UserEventGetOauthURLWithProvider(
      OauthProviderPB.fromObject({
        provider,
      })
    );

    if (!providerDataRes.ok) {
      Log.error(providerDataRes.val.msg);
      throw new Error(providerDataRes.val.msg);
    }

    const providerData = providerDataRes.val;

    return providerData.oauth_url;
  },

  signInWithOAuth: async ({ uri, deviceId }: { uri: string; deviceId: string }) => {
    const payload = OauthSignInPB.fromObject({
      authenticator: AuthenticatorPB.AppFlowyCloud,
      map: {
        sign_in_url: uri,
        device_id: deviceId,
      },
    });

    const res = await UserEventOauthSignIn(payload);

    if (!res.ok) {
      Log.error(res.val.msg);
      throw new Error(res.val.msg);
    }

    return res.val;
  },

  signUp: async (params: { deviceId: string; name: string; email: string; password: string }) => {
    const payload = SignUpPayloadPB.fromObject({
      name: params.name,
      email: params.email,
      password: params.password,
      device_id: params.deviceId,
    });

    const res = await UserEventSignUp(payload);

    if (!res.ok) {
      Log.error(res.val.msg);
      throw new Error(res.val.msg);
    }

    return res.val;
  },

  signOut: () => {
    return UserEventSignOut();
  },

  signIn: async (email: string, password: string) => {
    const payload = SignInPayloadPB.fromObject({
      email,
      password,
    });

    const res = await UserEventSignInWithEmailPassword(payload);

    if (!res.ok) {
      Log.error(res.val.msg);
      throw new Error(res.val.msg);
    }

    return res.val;
  },
};
