export function getPlatform () {
  return {
    isTauri: !!import.meta.env.TAURI_PLATFORM,
    usedWasm: import.meta.env.AF_TARGET_WASM,
  };
}