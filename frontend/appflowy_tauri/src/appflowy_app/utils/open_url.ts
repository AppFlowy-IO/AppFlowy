import { open as openWindow } from '@tauri-apps/api/shell';

export const pattern = /^(https?:\/\/)?([\da-z.-]+)\.([a-z.]{2,6})([/\w.-]*)*\/?$/;

export function openUrl(str: string) {
  if (pattern.test(str)) {
    const linkPrefix = ['http://', 'https://', 'file://', 'ftp://', 'ftps://', 'mailto:'];

    if (linkPrefix.some((prefix) => str.startsWith(prefix))) {
      void openWindow(str);
    } else {
      void openWindow('https://' + str);
    }
  } else {
    // open google search
    void openWindow('https://www.google.com/search?q=' + encodeURIComponent(str));
  }
}
