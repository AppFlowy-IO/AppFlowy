import { UserProfile } from '@/application/user.type';
import { getDB } from '@/application/services/js-services/db';
import { getAuthInfo } from '@/application/services/js-services/storage/token';

const primaryKeyName = 'uid';

export async function getSignInUser(): Promise<UserProfile | undefined> {
  const db = getDB();
  const authInfo = getAuthInfo();

  return db?.users.get(authInfo?.uuid);
}

export async function setSignInUser(profile: UserProfile) {
  const db = getDB();

  return db?.users.put(profile, primaryKeyName);
}
