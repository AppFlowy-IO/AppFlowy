import { AFServiceConfig } from '@/application/services/services.type';
import { CloudService } from '@/application/services/wasm-services/cloud.service';

export class AFWasmService {
  cloudService: CloudService;

  constructor(private config: AFServiceConfig) {
    this.cloudService = new CloudService(config.cloudConfig);
  }

  async load() {
    await this.cloudService.init();
  }
}
