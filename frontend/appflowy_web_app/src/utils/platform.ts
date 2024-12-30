export function getPlatform () {
  return {
    isTauri: !!import.meta.env.TAURI_PLATFORM,
    isMobile: /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent),
  };
}
