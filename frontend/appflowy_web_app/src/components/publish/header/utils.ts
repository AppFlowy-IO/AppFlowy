import { View } from '@/application/types';
import { getOS, openAppOrDownload } from '@/utils/open_schema';
import { iosDownloadLink, androidDownloadLink, desktopDownloadLink, openAppFlowySchema } from '@/utils/url';

export function openOrDownload () {
  const os = getOS();
  const downloadUrl = os === 'ios' ? iosDownloadLink : os === 'android' ? androidDownloadLink : desktopDownloadLink;

  return openAppOrDownload({
    appScheme: openAppFlowySchema,
    downloadUrl,
  });
}

export function findAncestors (data: View[], targetId: string, currentPath: View[] = []): View[] | null {
  for (const item of data) {
    const newPath = [...currentPath, item];

    if (item.view_id === targetId) {
      return newPath;
    }

    if (item.children && item.children.length > 0) {
      const result = findAncestors(item.children, targetId, newPath);

      if (result) {
        return result;
      }
    }
  }

  return null;
}

export function findView (data: View[], targetId: string): View | null {
  for (const item of data) {
    if (item.view_id === targetId) {
      return item;
    }

    if (item.children && item.children.length > 0) {
      const result = findView(item.children, targetId);

      if (result) {
        return result;
      }
    }
  }

  return null;
}