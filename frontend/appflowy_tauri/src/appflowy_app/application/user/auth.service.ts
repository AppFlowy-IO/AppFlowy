import { SignInPayloadPB, SignUpPayloadPB } from '@/services/backend';
import {
  UserEventSignInWithEmailPassword,
  UserEventSignOut,
  UserEventSignUp,
} from '@/services/backend/events/flowy-user';
import { nanoid } from '@reduxjs/toolkit';
import { Log } from '$app/utils/log';

export const AuthService = {
  signIn: async (params: { email: string; password: string }) => {
    const payload = SignInPayloadPB.fromObject({ email: params.email, password: params.password });

    const res = await UserEventSignInWithEmailPassword(payload);

    if (res.ok) {
      return res.val;
    }

    Log.error(res.val.msg);
    throw new Error(res.val.msg);
  },

  signUp: async (params: { name: string; email: string; password: string }) => {
    const deviceId = nanoid(8);
    const payload = SignUpPayloadPB.fromObject({
      name: params.name,
      email: params.email,
      password: params.password,
      device_id: deviceId,
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
};
