export function getPlatform() {
  return {
    isTauri: !!import.meta.env.TAURI_PLATFORM,
  };
}
