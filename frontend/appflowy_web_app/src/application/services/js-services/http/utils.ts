import { UserProfilePB, WorkspacePB } from '@/application/services/js-services/http/http.type';
import { Authenticator, UserProfile, Workspace } from '@/application/services/user.type';
import axios, { AxiosInstance, InternalAxiosRequestConfig, AxiosResponse, AxiosRequestConfig } from 'axios';
import {
  ACCESS_TOKEN_NAME,
  AUTHORIZATION_NAME,
  gotrueHttpUrls,
  REFRESH_TOKEN_NAME,
  TOKEN_TYPE_NAME,
  URL_NAME,
} from '@/application/services/js-services/http/const';

async function refreshToken(instance: AxiosInstance) {
  const refreshToken = sessionStorage.getItem(REFRESH_TOKEN_NAME);

  if (!refreshToken) {
    throw new Error('Refresh token not found');
  }

  const { data } = await instance.post(gotrueHttpUrls[URL_NAME.REFRESH_TOKEN], {
    refresh_token: refreshToken,
  });

  sessionStorage.setItem(ACCESS_TOKEN_NAME, data.access_token);
  sessionStorage.setItem(REFRESH_TOKEN_NAME, data.refresh_token);

  return data.access_token;
}

export function getAxiosInstances(baseURL: string, gotrueURL: string) {
  const gotrueInstance = axios.create({
    baseURL: gotrueURL,
    headers: {
      'Content-Type': 'application/json',
      Accept: '*/*',
    },
  });
  const baseInstance = axios.create({
    baseURL,
    headers: {
      'Content-Type': 'application/json',
      Accept: '*/*',
    },
  });

  const requestInterceptor = async (config: InternalAxiosRequestConfig) => {
    const accessToken = sessionStorage.getItem(ACCESS_TOKEN_NAME);
    const tokenType = sessionStorage.getItem(TOKEN_TYPE_NAME) || 'Bearer';

    if (accessToken) {
      config.headers[AUTHORIZATION_NAME] = `${tokenType} ${accessToken}`;
    }

    return config;
  };

  const errorInterceptor = async (error: {
    response?: AxiosResponse;
    config: AxiosRequestConfig;
  }) => {
    if (error.response?.status === 401 && !error.config.url?.includes(gotrueHttpUrls[URL_NAME.LOGOUT])) {
      try {
        const tokenType = sessionStorage.getItem(TOKEN_TYPE_NAME) || 'Bearer';
        const accessToken = await refreshToken(gotrueInstance);

        const config = {
          ...error.config,
          [AUTHORIZATION_NAME]: `${tokenType} ${accessToken}`,
        }

        return gotrueInstance.request(config);
      } catch (e) {
        // do nothing
      }
    }

    return Promise.reject(error);
  };

  gotrueInstance.interceptors.request.use(requestInterceptor);
  gotrueInstance.interceptors.response.use((response) => response, errorInterceptor);

  baseInstance.interceptors.request.use(requestInterceptor);
  baseInstance.interceptors.response.use((response) => response, errorInterceptor);
  return {
    baseInstance,
    gotrueInstance,
  };
}

export function parseUserPBToUserProfile(userPB: UserProfilePB): UserProfile {
  return {
    id: userPB.id,
    email: userPB.email,
    authenticator: Authenticator.AppFlowyCloud,
    iconUrl: userPB.user_metadata.avatar_url,
  };
}

export function parseWorkspacePBToWorkspace(workspacePB: WorkspacePB): Workspace {
  return {
    id: workspacePB.workspace_id,
    name: workspacePB.workspace_name,
    icon: workspacePB.icon,
    owner: {
      id: workspacePB.owner_uid,
      name: workspacePB.owner_name,
    },
  };
}
