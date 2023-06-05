import { nanoid } from '@reduxjs/toolkit';
import {
  AuthTypePB,
  SignOutPB,
  UserEventCheckUser,
  UserEventGetUserProfile,
  UserEventSignIn,
  UserEventSignOut,
  UserEventSignUp,
  UserEventUpdateUserProfile,
} from '@/services/backend/events/flowy-user';
import {
  CreateWorkspacePayloadPB,
  SignInPayloadPB,
  SignUpPayloadPB,
  UpdateUserProfilePayloadPB,
  WorkspaceIdPB,
  WorkspacePB,
  WorkspaceSettingPB,
} from '@/services/backend';
import {
  FolderEventCreateWorkspace,
  FolderEventOpenWorkspace,
  FolderEventGetCurrentWorkspace,
  FolderEventReadAllWorkspaces,
} from '@/services/backend/events/flowy-folder2';

export class UserBackendService {
  constructor(public readonly userId: number) {}

  getUserProfile = () => {
    return UserEventGetUserProfile();
  };

  static checkUser = () => {
    return UserEventCheckUser();
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

  getCurrentWorkspace = async (): Promise<WorkspaceSettingPB> => {
    const result = await FolderEventGetCurrentWorkspace();
    if (result.ok) {
      return result.val;
    } else {
      throw new Error(result.val.msg);
    }
  };

  getWorkspaces = () => {
    const payload = WorkspaceIdPB.fromObject({});
    return FolderEventReadAllWorkspaces(payload);
  };

  openWorkspace = (workspaceId: string) => {
    const payload = WorkspaceIdPB.fromObject({ value: workspaceId });
    return FolderEventOpenWorkspace(payload);
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
    const payload = SignOutPB.fromObject({ auth_type: AuthTypePB.Local });
    return UserEventSignOut(payload);
  };
}

export class AuthBackendService {
  signIn = (params: { email: string; password: string }) => {
    const payload = SignInPayloadPB.fromObject({ email: params.email, password: params.password });
    return UserEventSignIn(payload);
  };

  signUp = (params: { name: string; email: string; password: string }) => {
    const payload = SignUpPayloadPB.fromObject({ name: params.name, email: params.email, password: params.password });
    return UserEventSignUp(payload);
  };

  signOut = () => {
    const payload = SignOutPB.fromObject({ auth_type: AuthTypePB.Local });
    return UserEventSignOut(payload);
  };

  autoSignUp = () => {
    const password = 'AppFlowy123@';
    const email = nanoid(4) + '@appflowy.io';
    return this.signUp({ name: 'Me', email: email, password: password });
  };
}
