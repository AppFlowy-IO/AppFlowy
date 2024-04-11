import { getAuthInfo } from '@/application/services/js-services/storage/token';
import { openDB } from '@/application/services/js-services/db';

export async function signInSuccess () {
  const authInfo = getAuthInfo();
  if (authInfo) {
    // Open the database
    openDB(authInfo.uuid);
  }
}