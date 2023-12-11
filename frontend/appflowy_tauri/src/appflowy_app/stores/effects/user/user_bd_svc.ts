import { nanoid } from '@reduxjs/toolkit';
import {
  AppearanceSettingsPB,
  UserEventGetAppearanceSetting,
  UserEventGetUserProfile,
  UserEventGetUserSetting,
  UserEventSetAppearanceSetting,
  UserEventSignInWithEmailPassword,
  UserEventSignOut,
  UserEventSignUp,
  UserEventUpdateUserProfile,
} from '@/services/backend/events/flowy-user';
import {
  CreateWorkspacePayloadPB,
  SignInPayloadPB,
  SignUpPayloadPB,
  UpdateUserProfilePayloadPB,
  WorkspacePB,
  WorkspaceSettingPB,
} from '@/services/backend';
import {
  FolderEventCreateWorkspace,
  FolderEventGetCurrentWorkspaceSetting,
  FolderEventReadCurrentWorkspace,
} from '@/services/backend/events/flowy-folder2';

export class UserBackendService {
  constructor(public readonly userId: number) {}

  static getUserProfile = () => {
    return UserEventGetUserProfile();
  };

  updateUserProfile = (params: { name?: string; password?: string; email?: string; openAIKey?: string }) => {
    const payload = UpdateUserProfilePayloadPB.fromObject({ id: this.userId });

    if (params.name !== undefined) {
      payload.name = params.name;
    }

    if (params.password !== undefined) {
      payload.password = params.password;
    }

    if (params.email !== undefined) {
      payload.email = params.email;
    }

    // if (params.openAIKey !== undefined) {
    // }
    return UserEventUpdateUserProfile(payload);
  };

  getCurrentWorkspaceSetting = async (): Promise<WorkspaceSettingPB> => {
    const result = await FolderEventGetCurrentWorkspaceSetting();

    if (result.ok) {
      return result.val;
    } else {
      throw new Error(result.val.msg);
    }
  };

  getWorkspaces = () => {
    return FolderEventReadCurrentWorkspace();
  };

  createWorkspace = async (params: { name: string; desc: string }): Promise<WorkspacePB> => {
    const payload = CreateWorkspacePayloadPB.fromObject({ name: params.name, desc: params.desc });
    const result = await FolderEventCreateWorkspace(payload);

    if (result.ok) {
      return result.val;
    } else {
      throw new Error(result.val.msg);
    }
  };

  signOut = () => {
    return UserEventSignOut();
  };

  setAppearanceSettings = (params: ReturnType<typeof AppearanceSettingsPB.prototype.toObject>) => {
    const payload = AppearanceSettingsPB.fromObject(params);

    return UserEventSetAppearanceSetting(payload);
  };

  getAppearanceSettings = () => {
    return UserEventGetAppearanceSetting();
  };

  getStorageSettings = () => {
    return UserEventGetUserSetting();
  };
}

export class AuthBackendService {
  signIn = (params: { email: string; password: string }) => {
    const payload = SignInPayloadPB.fromObject({ email: params.email, password: params.password });
    
    return UserEventSignInWithEmailPassword(payload);
  };

  signUp = (params: { name: string; email: string; password: string }) => {
    const deviceId = nanoid(8);
    const payload = SignUpPayloadPB.fromObject({
      name: params.name,
      email: params.email,
      password: params.password,
      device_id: deviceId,
    });

    return UserEventSignUp(payload);
  };

  signOut = () => {
    return UserEventSignOut();
  };

  autoSignUp = () => {
    const password = 'AppFlowy123@';
    const email = nanoid(4) + '@appflowy.io';

    return this.signUp({ name: 'Me', email: email, password: password });
  };
}
