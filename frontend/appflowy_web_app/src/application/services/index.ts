import { AFService, AFServiceConfig } from '@/application/services/services.type';
import { AFClientService } from '$client-services';

let service: AFService;

export async function getService(config: AFServiceConfig) {
  if (service) return service;

  service = new AFClientService(config);
  await service.load();
  return service;
}
