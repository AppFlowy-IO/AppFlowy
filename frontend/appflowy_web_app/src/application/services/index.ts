import { AFService, AFServiceConfig } from '@/application/services/services.type';
import { getPlatform } from '@/utils/platform';

let service: AFService;

export async function getService(config: AFServiceConfig) {
  if (service) return service;
  const platformInfo = getPlatform();

  let Service;

  if (platformInfo.isTauri) {
    Service = (await import('./tauri-services')).AFTauriService;
  } else {
    Service = (await import('./js-services')).AFJSService;
  }

  service = new Service(config);
  await service.load();
  return service;
}
