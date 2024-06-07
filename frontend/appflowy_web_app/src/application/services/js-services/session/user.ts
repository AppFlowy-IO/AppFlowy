import { UserProfile, UserWorkspace, Workspace } from '@/application/user.type';

const userKey = 'user';
const workspaceKey = 'workspace';

export async function getSignInUser(): Promise<UserProfile | undefined> {
  const userStr = localStorage.getItem(userKey);

  try {
    return userStr ? JSON.parse(userStr) : undefined;
  } catch (e) {
    return undefined;
  }
}

export async function setSignInUser(profile: UserProfile) {
  const userStr = JSON.stringify(profile);

  localStorage.setItem(userKey, userStr);
}

export async function getUserWorkspace(): Promise<UserWorkspace | undefined> {
  const str = localStorage.getItem(workspaceKey);

  try {
    return str ? JSON.parse(str) : undefined;
  } catch (e) {
    return undefined;
  }
}

export async function setUserWorkspace(workspace: UserWorkspace) {
  const str = JSON.stringify(workspace);

  localStorage.setItem(workspaceKey, str);
}

export async function getCurrentWorkspace(): Promise<Workspace | undefined> {
  const userProfile = await getSignInUser();
  const userWorkspace = await getUserWorkspace();

  return userWorkspace?.workspaces.find((workspace) => workspace.id === userProfile?.workspaceId);
}
