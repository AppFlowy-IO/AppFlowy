import { getPlatform } from '@/utils/platform';
import isURL from 'validator/lib/isURL';
import isIP from 'validator/lib/isIP';
import isFQDN from 'validator/lib/isFQDN';

export const downloadPage = 'https://appflowy.io/download';

export const openAppFlowySchema = 'appflowy-flutter://';

export const iosDownloadLink = 'https://apps.apple.com/app/appflowy/id6457261352';
export const androidDownloadLink = 'https://play.google.com/store/apps/details?id=io.appflowy.appflowy';

export const desktopDownloadLink = 'https://appflowy.io/download/#pop';

export function isValidUrl (input: string) {
  return isURL(input, { require_protocol: true, require_host: false });
}

// Process the URL to make sure it's a valid URL
// If it's not a valid URL(eg: 'appflowy.io' or '192.168.1.2'), we'll add 'https://' to the URL
export function processUrl (input: string) {
  let processedUrl = input;

  if (isValidUrl(input)) {
    return processedUrl;
  }

  if (input.startsWith('http')) {
    return processedUrl;
  }

  if (input.startsWith('localhost')) {
    return `http://${input}`;
  }

  const domain = input.split('/')[0];

  if (isIP(domain) || isFQDN(domain)) {
    processedUrl = `https://${input}`;
    if (isValidUrl(processedUrl)) {
      return processedUrl;
    }
  }

  return;
}

export async function openUrl (url: string, target: string = '_current') {
  const platform = getPlatform();

  const newUrl = processUrl(url);

  if (!newUrl) return;
  if (platform.isTauri) {
    const { open } = await import('@tauri-apps/api/shell');

    await open(newUrl);
    return;
  }

  window.open(newUrl, target);
}
