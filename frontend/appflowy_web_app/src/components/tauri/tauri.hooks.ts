import { useCallback } from 'react';
import { notify } from '@/components/_shared/notify';

export function useDeepLink() {
  const onDeepLink = useCallback(async () => {
    const { event } = await import('@tauri-apps/api');

    // On macOS You still have to install a .app bundle you got from tauri build --debug for this to work!
    return await event.listen('open_deep_link', async (e) => {
      const payload = e.payload as string;

      const [, hash] = payload.split('//#');
      const obj = parseHash(hash);

      if (!obj.access_token) {
        notify.error('Failed to sign in, the access token is missing');
        // update login state to error
        return;
      }
    });
  }, []);

  return {
    onDeepLink,
  };
}

function parseHash(hash: string) {
  const hashParams = new URLSearchParams(hash);
  const hashObject: Record<string, string> = {};

  for (const [key, value] of hashParams) {
    hashObject[key] = value;
  }

  return hashObject;
}
