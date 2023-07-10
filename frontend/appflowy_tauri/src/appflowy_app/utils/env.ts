export function isApple() {
  return typeof navigator !== 'undefined' && /Mac OS X/.test(navigator.userAgent);
}

export function isTauri() {
  // eslint-disable-next-line @typescript-eslint/ban-ts-comment
  // @ts-ignore
  const isTauri = window.__TAURI__;

  return isTauri;
}
