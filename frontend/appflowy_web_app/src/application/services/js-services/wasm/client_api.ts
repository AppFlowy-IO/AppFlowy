import { ClientAPI } from '@appflowyinc/client-api-wasm';
import { UserProfile } from '@/application/user.type';
import { AFCloudConfig } from '@/application/services/services.type';
import { invalidToken, readTokenStr, writeToken } from '@/application/services/js-services/storage';
import { CollabType } from '@/application/collab.type';

let client: ClientAPI;

export function initAPIService (config: AFCloudConfig & {
  deviceId: string;
  clientId: string;
}) {
  window.refresh_token = writeToken;
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

  const token = readTokenStr();

  if (token) {
    client.restore_token(token);
  }

  client.subscribe();
}

export function signIn (email: string, password: string) {
  return client.login(email, password);
}

export function logout () {
  return client.logout();
}

export async function getUser (): Promise<UserProfile> {
  try {
    const user = await client.get_user();

    if (!user) {
      throw new Error('No user found');
    }

    return {
      uid: parseInt(user.uid),
      uuid: user.uuid || undefined,
      email: user.email || undefined,
      name: user.name || undefined,
      workspaceId: user.latest_workspace_id,
      iconUrl: user.icon_url || undefined,
    };
  } catch (e) {
    return Promise.reject(e);
  }
}

export async function getCollab (workspaceId: string, object_id: string, collabType: CollabType) {
  const res = await client.get_collab({
    workspace_id: workspaceId,
    object_id: object_id,
    collab_type: Number(collabType) as 0 | 1 | 2 | 3 | 4 | 5,
  });

  const state = new Uint8Array(res.doc_state);

  return {
    state,
  };
}
