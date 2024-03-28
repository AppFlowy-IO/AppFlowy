import { CloudServiceEventPayload } from '@/application/services/wasm-services/cloud.type';
import { AFCloudConfig } from '@/application/services/services.type';

export class CloudService {
  constructor(private config: AFCloudConfig) {
    // Do nothing
  }

  async init() {
    // await init_client_api(
    //   JSON.stringify({
    //     base_url: this.config.baseURL,
    //     gotrue_url: this.config.gotrueURL,
    //     ws_url: this.config.wsURL,
    //   })
    // );
  }

  async asyncEvent(name: string, payload: CloudServiceEventPayload) {
    // await async_event(name, JSON.stringify(payload));
  }
}
