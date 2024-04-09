import { CloudServiceConfig } from '@/application/services/wasm-services/cloud.type';

// import { ClientAPI } from '@appflowyinc/client-api-wasm';

export class CloudService {
  // private client?: ClientAPI;

  constructor (private config: CloudServiceConfig) {
    // Do nothing
  }

  async init () {
    // this.client = ClientAPI.new({
    //   base_url: this.config.baseURL,
    //   ws_addr: this.config.wsURL,
    //   gotrue_url: this.config.gotrueURL,
    //   device_id: this.config.deviceId,
    //   client_id: this.config.clientId,
    //   configuration: {
    //     compression_quality: 8,
    //     compression_buffer_size: 10240,
    //   },
    // });

  }

  // async signIn (email: string, password: string) {
  //   try {
  //     const res = await this.client?.sign_in_password(email, password);
  //
  //     console.log(res);
  //   } catch (error) {
  //     console.error(error);
  //   }
  // }
}
