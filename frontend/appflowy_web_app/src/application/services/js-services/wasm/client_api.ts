import { getToken, invalidToken, isTokenValid, refreshToken } from '@/application/session/token';
import { ClientAPI } from '@appflowyinc/client-api-wasm';
import { AFCloudConfig } from '@/application/services/services.type';
import { PublishViewMetaData, ViewLayout } from '@/application/collab.type';

let client: ClientAPI;

export function initAPIService(
  config: AFCloudConfig & {
    deviceId: string;
    clientId: string;
  }
) {
  if (client) {
    return;
  }

  window.refresh_token = refreshToken;

  window.invalid_token = invalidToken;

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

  if (isTokenValid()) {
    client.restore_token(getToken() || '');
  }

  client.subscribe();
}

export async function getPublishView(publishNamespace: string, publishName: string) {
  const data = await client.get_publish_view(publishNamespace, publishName);

  const meta = JSON.parse(data.meta.data) as PublishViewMetaData;

  if (meta.view.layout === ViewLayout.Document) {
    return {
      data: data.data,
      meta,
    };
  }

  try {
    const decoder = new TextDecoder('utf-8');
    const jsonStr = decoder.decode(new Uint8Array(data.data));
    const res = JSON.parse(jsonStr) as {
      database_collab: number[];
      database_row_collabs: Record<string, number[]>;
      database_row_document_collabs: Record<string, number[]>;
      visible_database_view_ids: string[];
    };

    console.log('getPublishView', res);
    return {
      data: res.database_collab,
      rows: res.database_row_collabs,
      visibleViewIds: res.visible_database_view_ids,
      meta,
    };
  } catch (e) {
    return Promise.reject(e);
  }
}

export async function getPublishInfoWithViewId(viewId: string) {
  return client.get_publish_info(viewId);
}

export async function getPublishViewMeta(publishNamespace: string, publishName: string) {
  const data = await client.get_publish_view_meta(publishNamespace, publishName);
  const metadata = JSON.parse(data.data) as PublishViewMetaData;

  return metadata;
}

export async function signInWithUrl(url: string) {
  return client.sign_in_with_url(url);
}

export async function signInWithMagicLink(email: string, redirectTo: string) {
  return client.sign_in_with_magic_link(email, redirectTo);
}

export async function signInGoogle(redirectTo: string) {
  return signInProvider('google', redirectTo);
}

export async function signInProvider(provider: string, redirectTo: string) {
  try {
    const { url } = await client.generate_oauth_url_with_provider(provider, redirectTo);

    window.open(url, '_current');
  } catch (e) {
    return Promise.reject(e);
  }
}

export async function signInGithub(redirectTo: string) {
  return signInProvider('github', redirectTo);
}

export async function signInDiscord(redirectTo: string) {
  return signInProvider('discord', redirectTo);
}
