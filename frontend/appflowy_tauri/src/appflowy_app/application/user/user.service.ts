import { Theme, ThemeMode, UserSetting } from '$app_reducers/current-user/slice';
import { AppearanceSettingsPB, UpdateUserProfilePayloadPB } from '@/services/backend';
import {
  UserEventGetAppearanceSetting,
  UserEventGetUserProfile,
  UserEventSetAppearanceSetting,
  UserEventUpdateUserProfile,
} from '@/services/backend/events/flowy-user';

export const UserService = {
  getAppearanceSetting: async (): Promise<Partial<UserSetting> | undefined> => {
    const appearanceSetting = await UserEventGetAppearanceSetting();

    if (appearanceSetting.ok) {
      const res = appearanceSetting.val;
      const { locale, theme = Theme.Default, theme_mode = ThemeMode.Light } = res;
      let language = 'en';

      if (locale.language_code && locale.country_code) {
        language = `${locale.language_code}-${locale.country_code}`;
      } else if (locale.language_code) {
        language = locale.language_code;
      }

      return {
        themeMode: theme_mode,
        theme: theme as Theme,
        language: language,
      };
    }

    return;
  },

  setAppearanceSetting: async (params: ReturnType<typeof AppearanceSettingsPB.prototype.toObject>) => {
    const payload = AppearanceSettingsPB.fromObject(params);

    const res = await UserEventSetAppearanceSetting(payload);

    if (res.ok) {
      return res.val;
    }

    return Promise.reject(res.err);
  },

  getUserProfile: async () => {
    const res = await UserEventGetUserProfile();

    if (res.ok) {
      return res.val;
    }

    return;
  },

  updateUserProfile: async (params: ReturnType<typeof UpdateUserProfilePayloadPB.prototype.toObject>) => {
    const payload = UpdateUserProfilePayloadPB.fromObject(params);

    const res = await UserEventUpdateUserProfile(payload);

    if (res.ok) {
      return res.val;
    }

    return Promise.reject(res.err);
  },
};
