export function isApple() {
  return typeof navigator !== 'undefined' && /Mac OS X/.test(navigator.userAgent);
}
