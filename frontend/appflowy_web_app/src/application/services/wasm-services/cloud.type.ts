import { AFCloudConfig } from '@/application/services/services.type';

export type CloudServiceEventPayload = Record<string, string>;
export type CloudServiceConfig = AFCloudConfig & {
  deviceId: string;
  clientId: string;
}