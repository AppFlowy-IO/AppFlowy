import { open as openWindow } from '@tauri-apps/api/shell';

const urlPattern = /^(https?:\/\/)?([\da-z.-]+)\.([a-z.]{2,6})(\S*)*\/?(\?[=&\w.%-]*)?(#[\w.\-!~*'()]*)?$/;
const ipPattern = /^(https?:\/\/)?(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})(:\d{1,5})?$/;

export function isUrl(str: string) {
  return urlPattern.test(str) || ipPattern.test(str);
}

export function openUrl(str: string) {
  if (isUrl(str)) {
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
