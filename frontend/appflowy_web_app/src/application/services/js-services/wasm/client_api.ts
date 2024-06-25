import { ClientAPI } from '@appflowyinc/client-api-wasm';
import { AFCloudConfig } from '@/application/services/services.type';

let client: ClientAPI;

export function initAPIService(
  config: AFCloudConfig & {
    deviceId: string;
    clientId: string;
  }
) {
  window.refresh_token = () => {
    //
  };

  window.invalid_token = () => {
    // invalidToken();
  };

  client = ClientAPI.new({
    base_url: config.baseURL,
    ws_addr: config.wsURL,
    gotrue_url: config.gotrueURL,
    device_id: config.deviceId,
    client_id: config.clientId,
    configuration: {
      compression_quality: 8,
      compression_buffer_size: 10240,
    },
  });

  client.subscribe();
}

export async function getPublishView(publishNamespace: string, publishName: string) {
  return client.get_publish_view(publishNamespace, publishName);
}

export async function getPublishInfoWithViewId(viewId: string) {
  return client.get_publish_info(viewId);
}

export async function getPublishViewMeta(publishNamespace: string, publishName: string) {
  return client.get_publish_view_meta(publishNamespace, publishName);
}
