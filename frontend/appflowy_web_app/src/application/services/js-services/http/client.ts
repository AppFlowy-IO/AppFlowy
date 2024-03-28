import { AxiosInstance } from 'axios';
import { UserProfile, Workspace } from '@/application/services/user.type';
import {
  CollabType,
  EncodedCollab,
  UserProfilePB,
  WorkspacePB,
} from '@/application/services/js-services/http/http.type';
import {
  parseUserPBToUserProfile,
  getAxiosInstances,
  parseWorkspacePBToWorkspace,
} from '@/application/services/js-services/http/utils';
import {
  ACCESS_TOKEN_NAME,
  baseHttpUrls,
  gotrueHttpUrls,
  REFRESH_TOKEN_NAME,
  URL_NAME,
} from '@/application/services/js-services/http/const';

export class HttpClient {
  private gotrueAPI: AxiosInstance;
  private baseAPI: AxiosInstance;

  constructor(private config: { baseURL: string; gotrueURL: string }) {
    const { baseInstance, gotrueInstance } = getAxiosInstances(config.baseURL, config.gotrueURL);

    this.gotrueAPI = gotrueInstance;
    this.baseAPI = baseInstance;
  }

  async signInWithEmailPassword(email: string, password: string): Promise<UserProfile> {
    const { data } = await this.gotrueAPI.post<{
      access_token: string;
      refresh_token: string;
    }>(gotrueHttpUrls[URL_NAME.SIGN_IN_WITH_EMAIL], {
      email,
      password,
    });

    sessionStorage.setItem(ACCESS_TOKEN_NAME, data.access_token);
    sessionStorage.setItem(REFRESH_TOKEN_NAME, data.refresh_token);

    return this.getUser();
  }

  async getUser(): Promise<UserProfile> {
    const { data } = await this.gotrueAPI.get<UserProfilePB>(gotrueHttpUrls[URL_NAME.GET_USER]);

    return parseUserPBToUserProfile(data);
  }

  async logout() {
    await this.gotrueAPI.post(gotrueHttpUrls[URL_NAME.LOGOUT]);
    sessionStorage.removeItem(REFRESH_TOKEN_NAME);
    sessionStorage.removeItem(ACCESS_TOKEN_NAME);
  }

  async getWorkspaces(): Promise<Workspace[]> {
    const { data } = await this.baseAPI.get<WorkspacePB[]>(baseHttpUrls[URL_NAME.GET_WORKSPACES]);

    return data.map(parseWorkspacePBToWorkspace);
  }

  /**
   * Get object(document/database/view) from workspace
   * @param workspaceId - workspace id
   * @param objectId - document id or database id or view id
   * @param objectType - type of object [CollabType]
   */
  async getObject(workspaceId: string, objectId: string, objectType: CollabType): Promise<EncodedCollab> {
    // const workspaces = await this.getWorkspaces();
    //
    // console.log(workspaces);
    const { data } = await this.baseAPI.get<EncodedCollab>(baseHttpUrls[URL_NAME.GET_OBJECT](workspaceId, objectId), {
      data: JSON.stringify({
        workspace_id: workspaceId,
        object_id: objectId,
        collab_type: objectType,
      }),
    });

    return data;
  }
}
