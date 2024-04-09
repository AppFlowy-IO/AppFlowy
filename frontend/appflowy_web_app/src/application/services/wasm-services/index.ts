import { AFServiceConfig } from '@/application/services/services.type';
import { CloudService } from '@/application/services/wasm-services/cloud.service';

export class AFWasmService {
  cloudService: CloudService;

  constructor (private config: AFServiceConfig, clientConfig: {
    deviceId: string;
    clientId: string;
  }) {
    this.cloudService = new CloudService({
      ...config.cloudConfig,
      ...clientConfig,
    });
  }

  async load () {
    await this.cloudService.init();
  }
}
