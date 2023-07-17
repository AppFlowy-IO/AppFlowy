import { UserBackendService } from '$app/stores/effects/user/user_bd_svc';
import { AppearanceSettingsPB, ThemeModePB } from '@/services/backend';

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

  getAppearanceSetting = async (): Promise<AppearanceSettingsPB | undefined> => {
    const appearanceSetting = await this.backendService.getAppearanceSettings();

    if (appearanceSetting.ok) {
      return appearanceSetting.val;
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
