export function getPlatform() {
  return {
    isTauri: !!import.meta.env.TAURI_PLATFORM,
    isMobile: window.navigator.userAgent.match(/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i),
  };
}
