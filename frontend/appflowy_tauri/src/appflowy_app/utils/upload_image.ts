export const MAX_IMAGE_SIZE = 10 * 1024 * 1024; // 10MB
export const ALLOWED_IMAGE_EXTENSIONS = ['jpg', 'jpeg', 'png', 'gif', 'svg', 'webp'];
export const IMAGE_DIR = 'images';

export function getFileName(url: string) {
  const [...parts] = url.split('/');

  return parts.pop() ?? url;
}
