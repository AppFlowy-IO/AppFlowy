import { getPlatform } from '@/utils/platform';
import validator from 'validator';

export const downloadPage = 'https://appflowy.io/download';

export const openAppFlowySchema = 'appflowy-flutter://';

export function isValidUrl(input: string) {
  return validator.isURL(input, { require_protocol: true, require_host: false });
}

// Process the URL to make sure it's a valid URL
// If it's not a valid URL(eg: 'appflowy.io' or '192.168.1.2'), we'll add 'https://' to the URL
export function processUrl(input: string) {
  let processedUrl = input;

  if (isValidUrl(input)) {
    return processedUrl;
  }

  const domain = input.split('/')[0];

  if (validator.isIP(domain) || validator.isFQDN(domain)) {
    processedUrl = `https://${input}`;
    if (isValidUrl(processedUrl)) {
      return processedUrl;
    }
  }

  return;
}

export async function openUrl(url: string, target: string = '_current') {
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
