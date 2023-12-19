import { UserBackendService } from '$app/stores/effects/user/user_bd_svc';
import { AppearanceSettingsPB } from '@/services/backend';
import { Theme, ThemeMode, UserSetting } from '$app/stores/reducers/current-user/slice';

export class UserSettingController {
  private readonly backendService: UserBackendService;
  constructor(private userId: number) {
    this.backendService = new UserBackendService(userId);
  }

  getStorageSettings = async () => {
    const userSetting = await this.backendService.getStorageSettings();

    if (userSetting.ok) {
      return userSetting.val;
    }

    return {};
  };

  getAppearanceSetting = async (): Promise<Partial<UserSetting> | undefined> => {
    const appearanceSetting = await this.backendService.getAppearanceSettings();

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
  };

  setAppearanceSetting = async (params: ReturnType<typeof AppearanceSettingsPB.prototype.toObject>) => {
    const res = await this.backendService.setAppearanceSettings(params);

    if (res.ok) {
      return res.val;
    }

    return Promise.reject(res.err);
  };
}
