import {
  DatabaseId,
  FolderView,
  RowId,
  User,
  View,
  ViewId,
  ViewLayout,
  Workspace,
  Invitation,
  Types,
  AFWebUser,
  GetRequestAccessInfoResponse,
  Subscriptions,
  SubscriptionPlan,
  SubscriptionInterval,
  RequestAccessInfoStatus,
} from '@/application/types';
import { GlobalComment, Reaction } from '@/application/comment.type';
import { initGrantService, refreshToken } from '@/application/services/js-services/http/gotrue';
import { blobToBytes } from '@/application/services/js-services/http/utils';
import { AFCloudConfig } from '@/application/services/services.type';
import { getTokenParsed, invalidToken } from '@/application/session/token';
import {
  Template,
  TemplateCategory,
  TemplateCategoryFormValues,
  TemplateCreator, TemplateCreatorFormValues, TemplateSummary,
  UploadTemplatePayload,
} from '@/application/template.type';
import axios, { AxiosInstance } from 'axios';
import dayjs from 'dayjs';

export * from './gotrue';

let axiosInstance: AxiosInstance | null = null;

export function initAPIService (config: AFCloudConfig) {
  if (axiosInstance) {
    return;
  }

  axiosInstance = axios.create({
    baseURL: config.baseURL,
    headers: {
      'Content-Type': 'application/json',
    },
  });

  initGrantService(config.gotrueURL);

  axiosInstance.interceptors.request.use(
    async (config) => {
      const token = getTokenParsed();

      if (!token) {
        return config;
      }

      const isExpired = dayjs().isAfter(dayjs.unix(token.expires_at));

      let access_token = token.access_token;
      const refresh_token = token.refresh_token;

      if (isExpired) {
        const newToken = await refreshToken(refresh_token);

        access_token = newToken?.access_token || '';
      }

      if (access_token) {
        Object.assign(config.headers, {
          Authorization: `Bearer ${access_token}`,
        });
      }

      return config;
    },
    (error) => {
      return Promise.reject(error);
    },
  );

  axiosInstance.interceptors.response.use(async (response) => {
    const status = response.status;

    if (status === 401) {
      const token = getTokenParsed();

      if (!token) {
        invalidToken();
        return response;
      }

      const refresh_token = token.refresh_token;

      try {
        await refreshToken(refresh_token);
      } catch (e) {
        invalidToken();
      }
    }

    return response;
  });
}

export async function signInWithUrl (url: string) {
  const hash = new URL(url).hash;

  if (!hash) {
    return Promise.reject('No hash found');
  }

  const params = new URLSearchParams(hash.slice(1));
  const accessToken = params.get('access_token');
  const refresh_token = params.get('refresh_token');

  if (!accessToken || !refresh_token) {
    return Promise.reject({
      code: -1,
      message: 'No access token or refresh token found',
    });
  }

  try {
    await verifyToken(accessToken);
  } catch (e) {
    return Promise.reject({
      code: -1,
      message: 'Verify token failed',
    });
  }

  try {
    await refreshToken(refresh_token);
  } catch (e) {
    return Promise.reject({
      code: -1,
      message: 'Refresh token failed',
    });
  }
}

export async function verifyToken (accessToken: string) {
  const url = `/api/user/verify/${accessToken}`;
  const response = await axiosInstance?.get<{
    code: number;
    data?: {
      is_new: boolean;
    };
    message: string;
  }>(url);

  const data = response?.data;

  if (data?.code === 0 && data.data) {
    return data.data;
  }

  return Promise.reject(data);
}

export async function getCurrentUser (): Promise<User> {
  const url = '/api/user/profile';
  const response = await axiosInstance?.get<{
    code: number;
    data?: {
      uid: number;
      uuid: string;
      email: string;
      name: string;
      metadata: {
        icon_url: string;
      };
      encryption_sign: null;
      latest_workspace_id: string;
      updated_at: number;
    };
    message: string;
  }>(url);

  const data = response?.data;

  if (data?.code === 0 && data.data) {
    const { uid, uuid, email, name, metadata } = data.data;

    return {
      uid: String(uid),
      uuid,
      email,
      name,
      avatar: metadata.icon_url,
      latestWorkspaceId: data.data.latest_workspace_id,
    };
  }

  return Promise.reject(data);
}

interface AFWorkspace {
  workspace_id: string,
  owner_uid: number,
  owner_name: string,
  workspace_name: string,
  icon: string,
  created_at: string,
  member_count: number,
  database_storage_id: string,
}

function afWorkspace2Workspace (workspace: AFWorkspace): Workspace {
  return {
    id: workspace.workspace_id,
    owner: {
      uid: workspace.owner_uid,
      name: workspace.owner_name,
    },
    name: workspace.workspace_name,
    icon: workspace.icon,
    memberCount: workspace.member_count,
    databaseStorageId: workspace.database_storage_id,
    createdAt: workspace.created_at,
  };
}

export async function openWorkspace (workspaceId: string) {
  const url = `/api/workspace/${workspaceId}/open`;
  const response = await axiosInstance?.put<{
    code: number;
    message: string;
  }>(url);

  if (response?.data.code === 0) {
    return;
  }

  return Promise.reject(response?.data);
}

export async function getUserWorkspaceInfo (): Promise<{
  user_id: string;
  selected_workspace: Workspace;
  workspaces: Workspace[];
}> {
  const url = '/api/user/workspace';
  const response = await axiosInstance?.get<{
    code: number,
    message: string,
    data: {
      user_profile: {
        uuid: string;
      },
      visiting_workspace: AFWorkspace,
      workspaces: AFWorkspace[]
    }

  }>(url);

  const data = response?.data;

  if (data?.code === 0) {
    const { visiting_workspace, workspaces, user_profile } = data.data;

    return {
      user_id: user_profile.uuid,
      selected_workspace: afWorkspace2Workspace(visiting_workspace),
      workspaces: workspaces.map(afWorkspace2Workspace),
    };
  }

  return Promise.reject(data);
}

export async function getPublishViewMeta (namespace: string, publishName: string) {
  const url = `/api/workspace/published/${namespace}/${publishName}`;
  const response = await axiosInstance?.get(url);

  return response?.data;
}

export async function getPublishViewBlob (namespace: string, publishName: string) {
  const url = `/api/workspace/published/${namespace}/${publishName}/blob`;
  const response = await axiosInstance?.get(url, {
    responseType: 'blob',
  });

  return blobToBytes(response?.data);
}

export async function updateCollab (workspaceId: string, objectId: string, docState: Uint8Array, context: {
  version_vector: number;
}) {
  const url = `/api/workspace/v1/${workspaceId}/collab/${objectId}/web-update`;
  const response = await axiosInstance?.post<{
    code: number;
    message: string;
  }>(url, {
    doc_state: Array.from(docState),
  });

  if (response?.data.code !== 0) {
    return Promise.reject(response?.data);
  }

  return context;
}

export async function getCollab (workspaceId: string, objectId: string, collabType: Types) {
  const url = `/api/workspace/v1/${workspaceId}/collab/${objectId}`;
  const response = await axiosInstance?.get<{
    code: number;
    data: {
      doc_state: number[];
      object_id: string;
    };
    message: string;
  }>(url, {
    params: {
      collab_type: collabType,
    },
  });

  if (response?.data.code !== 0) {
    return Promise.reject(response?.data);
  }

  const docState = response?.data.data.doc_state;

  return {
    data: new Uint8Array(docState),
  };
}

export async function getPageCollab (workspaceId: string, viewId: string) {
  const url = `/api/workspace/${workspaceId}/page-view/${viewId}`;
  const response = await axiosInstance?.get<{
    code: number;
    data: {
      view: View;
      data: {
        encoded_collab: number[];
        row_data: Record<RowId, number[]>;
        owner?: User;
        last_editor?: User;
      }
    };
    message: string;
  }>(url);

  if (!response) {
    return Promise.reject('No response');
  }

  if (response.data.code !== 0) {
    return Promise.reject(response?.data);
  }

  const { encoded_collab, row_data, owner, last_editor } = response.data.data.data;

  return {
    data: new Uint8Array(encoded_collab),
    rows: row_data,
    owner,
    lastEditor: last_editor,
  };
}

export async function getPublishView (publishNamespace: string, publishName: string) {
  const meta = await getPublishViewMeta(publishNamespace, publishName);
  const blob = await getPublishViewBlob(publishNamespace, publishName);

  if (meta.view.layout === ViewLayout.Document) {
    return {
      data: blob,
      meta,
    };
  }

  try {
    const decoder = new TextDecoder('utf-8');

    const jsonStr = decoder.decode(blob);

    const res = JSON.parse(jsonStr) as {
      database_collab: Uint8Array;
      database_row_collabs: Record<RowId, number[]>;
      database_row_document_collabs: Record<string, number[]>;
      visible_database_view_ids: ViewId[];
      database_relations: Record<DatabaseId, ViewId>;
    };

    return {
      data: new Uint8Array(res.database_collab),
      rows: res.database_row_collabs,
      visibleViewIds: res.visible_database_view_ids,
      relations: res.database_relations,
      subDocuments: res.database_row_document_collabs,
      meta,
    };
  } catch (e) {
    return Promise.reject(e);
  }
}

export async function getPublishInfoWithViewId (viewId: string) {
  const url = `/api/workspace/published-info/${viewId}`;
  const response = await axiosInstance?.get<{
    code: number;
    data?: {
      namespace: string;
      publish_name: string;
    };
    message: string;
  }>(url);

  const data = response?.data;

  if (data?.code === 0 && data.data) {
    return data.data;
  }

  return Promise.reject(data);
}

export async function getAppFavorites (workspaceId: string) {
  const url = `/api/workspace/${workspaceId}/favorite`;
  const response = await axiosInstance?.get<{
    code: number;
    data?: {
      views: View[]
    };
    message: string;
  }>(url);

  const data = response?.data;

  if (data?.code === 0 && data.data) {
    return data.data.views;
  }

  return Promise.reject(data);
}

export async function getAppTrash (workspaceId: string) {
  const url = `/api/workspace/${workspaceId}/trash`;
  const response = await axiosInstance?.get<{
    code: number;
    data?: {
      views: View[]
    };
    message: string;
  }>(url);

  const data = response?.data;

  if (data?.code === 0 && data.data) {
    return data.data.views;
  }

  return Promise.reject(data);
}

export async function getAppRecent (workspaceId: string) {
  const url = `/api/workspace/${workspaceId}/recent`;
  const response = await axiosInstance?.get<{
    code: number;
    data?: {
      views: View[]
    };
    message: string;
  }>(url);

  const data = response?.data;

  if (data?.code === 0 && data.data) {
    return data.data.views;
  }

  return Promise.reject(data);
}

export async function getAppOutline (workspaceId: string) {
  const url = `/api/workspace/${workspaceId}/folder?depth=10`;

  const response = await axiosInstance?.get<{
    code: number;
    data?: View;
    message: string;
  }>(url);

  const data = response?.data;

  if (data?.code === 0 && data.data) {
    return data.data.children;
  }

  return Promise.reject(data);
}

export async function getView (workspaceId: string, viewId: string, depth: number = 1) {
  const url = `/api/workspace/${workspaceId}/folder?depth=${depth}&root_view_id=${viewId}`;
  const response = await axiosInstance?.get<{
    code: number;
    data?: View;
    message: string;
  }>(url);

  const data = response?.data;

  if (data?.code === 0 && data.data) {
    return data.data;
  }

  return Promise.reject(data);
}

export async function getPublishOutline (publishNamespace: string) {
  const url = `/api/workspace/published-outline/${publishNamespace}`;
  const response = await axiosInstance?.get<{
    code: number;
    data?: View;
    message: string;
  }>(url);

  const data = response?.data;

  if (data?.code === 0 && data.data) {
    return data.data.children;
  }

  return Promise.reject(data);
}

export async function getPublishViewComments (viewId: string): Promise<GlobalComment[]> {
  const url = `/api/workspace/published-info/${viewId}/comment`;
  const response = await axiosInstance?.get<{
    code: number;
    data?: {
      comments: {
        comment_id: string;
        user: {
          uuid: string;
          name: string;
          avatar_url: string | null;
        };
        content: string;
        created_at: string;
        last_updated_at: string;
        reply_comment_id: string | null;
        is_deleted: boolean;
        can_be_deleted: boolean;
      }[];
    };
    message: string;
  }>(url);

  const data = response?.data;

  if (data?.code === 0 && data.data) {
    const { comments } = data.data;

    return comments.map((comment) => {
      return {
        commentId: comment.comment_id,
        user: {
          uuid: comment.user?.uuid || '',
          name: comment.user?.name || '',
          avatarUrl: comment.user?.avatar_url || null,
        },
        content: comment.content,
        createdAt: comment.created_at,
        lastUpdatedAt: comment.last_updated_at,
        replyCommentId: comment.reply_comment_id,
        isDeleted: comment.is_deleted,
        canDeleted: comment.can_be_deleted,
      };
    });
  }

  return Promise.reject(data);
}

export async function getReactions (viewId: string, commentId?: string): Promise<Record<string, Reaction[]>> {
  let url = `/api/workspace/published-info/${viewId}/reaction`;

  if (commentId) {
    url += `?comment_id=${commentId}`;
  }

  const response = await axiosInstance?.get<{
    code: number;
    data?: {
      reactions: {
        reaction_type: string;
        react_users: {
          uuid: string;
          name: string;
          avatar_url: string | null;
        }[];
        comment_id: string;
      }[];
    };
    message: string;
  }>(url);

  const data = response?.data;

  if (data?.code === 0 && data.data) {
    const { reactions } = data.data;
    const reactionsMap: Record<string, Reaction[]> = {};

    for (const reaction of reactions) {
      if (!reactionsMap[reaction.comment_id]) {
        reactionsMap[reaction.comment_id] = [];
      }

      reactionsMap[reaction.comment_id].push({
        reactionType: reaction.reaction_type,
        commentId: reaction.comment_id,
        reactUsers: reaction.react_users.map((user) => ({
          uuid: user.uuid,
          name: user.name,
          avatarUrl: user.avatar_url,
        })),
      });
    }

    return reactionsMap;
  }

  return Promise.reject(data);
}

export async function createGlobalCommentOnPublishView (viewId: string, content: string, replyCommentId?: string) {
  const url = `/api/workspace/published-info/${viewId}/comment`;
  const response = await axiosInstance?.post<{ code: number; message: string }>(url, {
    content,
    reply_comment_id: replyCommentId,
  });

  if (response?.data.code === 0) {
    return;
  }

  return Promise.reject(response?.data.message);
}

export async function deleteGlobalCommentOnPublishView (viewId: string, commentId: string) {
  const url = `/api/workspace/published-info/${viewId}/comment`;
  const response = await axiosInstance?.delete<{ code: number; message: string }>(url, {
    data: {
      comment_id: commentId,
    },
  });

  if (response?.data.code === 0) {
    return;
  }

  return Promise.reject(response?.data.message);
}

export async function addReaction (viewId: string, commentId: string, reactionType: string) {
  const url = `/api/workspace/published-info/${viewId}/reaction`;
  const response = await axiosInstance?.post<{ code: number; message: string }>(url, {
    comment_id: commentId,
    reaction_type: reactionType,
  });

  if (response?.data.code === 0) {
    return;
  }

  return Promise.reject(response?.data.message);
}

export async function removeReaction (viewId: string, commentId: string, reactionType: string) {
  const url = `/api/workspace/published-info/${viewId}/reaction`;
  const response = await axiosInstance?.delete<{ code: number; message: string }>(url, {
    data: {
      comment_id: commentId,
      reaction_type: reactionType,
    },
  });

  if (response?.data.code === 0) {
    return;
  }

  return Promise.reject(response?.data.message);
}

export async function getWorkspaces (): Promise<Workspace[]> {
  const query = new URLSearchParams({
    include_member_count: 'true',
  });

  const url = `/api/workspace?${query.toString()}`;
  const response = await axiosInstance?.get<{
    code: number;
    data?: AFWorkspace[];
    message: string;
  }>(url);

  const data = response?.data;

  if (data?.code === 0 && data.data) {
    return data.data.map(afWorkspace2Workspace);
  }

  return Promise.reject(data);
}

export interface WorkspaceFolder {
  view_id: string;
  icon: string | null;
  name: string;
  is_space: boolean;
  is_private: boolean;
  extra: {
    is_space: boolean;
    space_created_at: number;
    space_icon: string;
    space_icon_color: string;
    space_permission: number;
  };

  children: WorkspaceFolder[];
}

function iterateFolder (folder: WorkspaceFolder): FolderView {
  return {
    id: folder.view_id,
    name: folder.name,
    icon: folder.icon,
    isSpace: folder.is_space,
    extra: folder.extra ? JSON.stringify(folder.extra) : null,
    isPrivate: folder.is_private,
    children: folder.children.map((child: WorkspaceFolder) => {
      return iterateFolder(child);
    }),
  };
}

export async function getWorkspaceFolder (workspaceId: string): Promise<FolderView> {
  const url = `/api/workspace/${workspaceId}/folder`;
  const response = await axiosInstance?.get<{
    code: number;
    data?: WorkspaceFolder;
    message: string;
  }>(url);

  const data = response?.data;

  if (data?.code === 0 && data.data) {
    return iterateFolder(data.data);
  }

  return Promise.reject(data);
}

export interface DuplicatePublishViewPayload {
  published_collab_type: 0 | 1 | 2 | 3 | 4 | 5 | 6;
  published_view_id: string;
  dest_view_id: string;
}

export async function duplicatePublishView (workspaceId: string, payload: DuplicatePublishViewPayload) {
  const url = `/api/workspace/${workspaceId}/published-duplicate`;

  const res = await axiosInstance?.post<{
    code: number;
    message: string;
  }>(url, payload);

  if (res?.data.code === 0) {
    return;
  }

  return Promise.reject(res?.data.message);
}

export async function createTemplate (template: UploadTemplatePayload) {
  const url = '/api/template-center/template';
  const response = await axiosInstance?.post<{
    code: number;
    message: string;
  }>(url, template);

  if (response?.data.code === 0) {
    return;
  }

  return Promise.reject(response?.data.message);
}

export async function updateTemplate (viewId: string, template: UploadTemplatePayload) {
  const url = `/api/template-center/template/${viewId}`;
  const response = await axiosInstance?.put<{
    code: number;
    message: string;
  }>(url, template);

  if (response?.data.code === 0) {
    return;
  }

  return Promise.reject(response?.data.message);
}

export async function getTemplates ({
  categoryId,
  nameContains,
}: {
  categoryId?: string;
  nameContains?: string;
}) {
  const url = `/api/template-center/template`;

  const response = await axiosInstance?.get<{
    code: number;
    data?: {
      templates: TemplateSummary[];
    };
    message: string;
  }>(url, {
    params: {
      category_id: categoryId,
      name_contains: nameContains,
    },
  });

  const data = response?.data;

  if (data?.code === 0 && data.data) {
    return data.data.templates;
  }

  return Promise.reject(data);
}

export async function getTemplateById (viewId: string) {
  const url = `/api/template-center/template/${viewId}`;
  const response = await axiosInstance?.get<{
    code: number;
    data?: Template;
    message: string;
  }>(url);

  const data = response?.data;

  if (data?.code === 0 && data.data) {
    return data.data;
  }

  return Promise.reject(data);
}

export async function deleteTemplate (viewId: string) {
  const url = `/api/template-center/template/${viewId}`;
  const response = await axiosInstance?.delete<{
    code: number;
    message: string;
  }>(url);

  if (response?.data.code === 0) {
    return;
  }

  return Promise.reject(response?.data.message);
}

export async function getTemplateCategories () {
  const url = '/api/template-center/category';
  const response = await axiosInstance?.get<{
    code: number;
    data?: {
      categories: TemplateCategory[]

    };
    message: string;
  }>(url);

  const data = response?.data;

  if (data?.code === 0 && data.data) {
    return data.data.categories;
  }

  return Promise.reject(data);
}

export async function addTemplateCategory (category: TemplateCategoryFormValues) {
  const url = '/api/template-center/category';
  const response = await axiosInstance?.post<{
    code: number;
    message: string;
  }>(url, category);

  if (response?.data.code === 0) {
    return;
  }

  return Promise.reject(response?.data.message);
}

export async function updateTemplateCategory (id: string, category: TemplateCategoryFormValues) {
  const url = `/api/template-center/category/${id}`;
  const response = await axiosInstance?.put<{
    code: number;
    message: string;
  }>(url, category);

  if (response?.data.code === 0) {
    return;
  }

  return Promise.reject(response?.data.message);
}

export async function deleteTemplateCategory (categoryId: string) {
  const url = `/api/template-center/category/${categoryId}`;
  const response = await axiosInstance?.delete<{
    code: number;
    message: string;
  }>(url);

  if (response?.data.code === 0) {
    return;
  }

  return Promise.reject(response?.data.message);
}

export async function getTemplateCreators () {
  const url = '/api/template-center/creator';
  const response = await axiosInstance?.get<{
    code: number;
    data?: {
      creators: TemplateCreator[];
    };
    message: string;
  }>(url);

  const data = response?.data;

  if (data?.code === 0 && data.data) {
    return data.data.creators;
  }

  return Promise.reject(data);
}

export async function createTemplateCreator (creator: TemplateCreatorFormValues) {
  const url = '/api/template-center/creator';
  const response = await axiosInstance?.post<{
    code: number;
    message: string;
  }>(url, creator);

  if (response?.data.code === 0) {
    return;
  }

  return Promise.reject(response?.data.message);
}

export async function updateTemplateCreator (creatorId: string, creator: TemplateCreatorFormValues) {
  const url = `/api/template-center/creator/${creatorId}`;
  const response = await axiosInstance?.put<{
    code: number;
    message: string;
  }>(url, creator);

  if (response?.data.code === 0) {
    return;
  }

  return Promise.reject(response?.data.message);
}

export async function deleteTemplateCreator (creatorId: string) {
  const url = `/api/template-center/creator/${creatorId}`;
  const response = await axiosInstance?.delete<{
    code: number;
    message: string;
  }>(url);

  if (response?.data.code === 0) {
    return;
  }

  return Promise.reject(response?.data.message);
}

export async function uploadFileToCDN (file: File) {
  const url = '/api/template-center/avatar';
  const formData = new FormData();

  formData.append('avatar', file);

  const response = await axiosInstance?.request<{
    code: number;
    data?: {
      file_id: string;
    };
    message: string;
  }>({
    method: 'PUT',
    url,
    data: formData,
    headers: {
      'Content-Type': 'multipart/form-data',
    },
  });

  const data = response?.data;

  if (data?.code === 0 && data.data) {
    return axiosInstance?.defaults.baseURL + '/api/template-center/avatar/' + data.data.file_id;
  }

  return Promise.reject(data);
}

export async function getInvitation (invitationId: string) {
  const url = `/api/workspace/invite/${invitationId}`;
  const response = await axiosInstance?.get<{
    code: number;
    data?: Invitation;
    message: string;
  }>(url);

  const data = response?.data;

  if (data?.code === 0 && data.data) {
    return data.data;
  }

  return Promise.reject(data);
}

export async function acceptInvitation (invitationId: string) {
  const url = `/api/workspace/accept-invite/${invitationId}`;
  const response = await axiosInstance?.post<{
    code: number;
    message: string;
  }>(url);

  if (response?.data.code === 0) {
    return;
  }

  return Promise.reject(response?.data.message);
}

export async function getRequestAccessInfo (requestId: string): Promise<GetRequestAccessInfoResponse> {
  const url = `/api/access-request/${requestId}`;
  const response = await axiosInstance?.get<{
    code: number;
    data?: {
      request_id: string;
      workspace: AFWorkspace;
      requester: AFWebUser & {
        email: string;
      };
      view: View;
      status: RequestAccessInfoStatus;
    };
    message: string;
  }>(url);

  const data = response?.data;

  if (data?.code === 0 && data.data) {
    const workspace = data.data.workspace;

    return {
      ...data.data,
      workspace: afWorkspace2Workspace(workspace),
    };
  }

  return Promise.reject(data);
}

export async function approveRequestAccess (requestId: string) {
  const url = `/api/access-request/${requestId}/approve`;
  const response = await axiosInstance?.post<{
    code: number;
    message: string;
  }>(url, {
    is_approved: true,
  });

  if (response?.data.code === 0) {
    return;
  }

  return Promise.reject(response?.data);
}

export async function sendRequestAccess (workspaceId: string, viewId: string) {
  const url = `/api/access-request`;
  const response = await axiosInstance?.post<{
    code: number;
    message: string;
  }>(url, {
    workspace_id: workspaceId,
    view_id: viewId,
  });

  if (response?.data.code === 0) {
    return;
  }

  return Promise.reject(response?.data);
}

export async function getSubscriptionLink (workspaceId: string, plan: SubscriptionPlan, interval: SubscriptionInterval) {
  const url = `/billing/api/v1/subscription-link`;
  const response = await axiosInstance?.get<{
    code: number;
    data?: string;
    message: string;
  }>(url, {
    params: {
      workspace_subscription_plan: plan,
      recurring_interval: interval,
      workspace_id: workspaceId,
      success_url: window.location.href,
    },
  });

  const data = response?.data;

  if (data?.code === 0 && data.data) {
    return data.data;
  }

  return Promise.reject(data);
}

export async function getSubscriptions () {
  const url = `/billing/api/v1/subscriptions`;
  const response = await axiosInstance?.get<{
    code: number;
    data: Subscriptions;
    message: string;
  }>(url);

  if (response?.data.code === 0) {
    return response?.data.data;
  }

  return Promise.reject(response?.data);

}

export async function getActiveSubscription (workspaceId: string) {
  const url = `/billing/api/v1/active-subscription/${workspaceId}`;

  const response = await axiosInstance?.get<{
    code: number;
    data: SubscriptionPlan[];
    message: string;
  }>(url);

  if (response?.data.code === 0) {
    return response?.data.data;
  }

  return Promise.reject(response?.data);
}

export async function importFile (file: File, onProgress: (progress: number) => void) {
  const url = `/api/import`;

  const fileName = file.name.split('.').slice(0, -1).join('.') || crypto.randomUUID();

  const fileSize = file.size;

  const mimeType = file.type || 'application/octet-stream';

  const validZipTypes = [
    'application/zip',
    'application/x-zip',
    'application/x-zip-compressed',
    'application/octet-stream',
  ];

  if (!validZipTypes.includes(mimeType) && !file.name.toLowerCase().endsWith('.zip')) {
    throw new Error('Please select a valid ZIP file.');
  }

  const formData = new FormData();

  formData.append(fileName, file, file.name);

  try {
    const response = await axios.post(url, formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
        'X-Content-Length': fileSize.toString(),
      },
      onUploadProgress: (progressEvent) => {
        const { progress = 0 } = progressEvent;

        console.log(`Upload progress: ${progress * 100}%`);
        onProgress(progress);
      },
    });

    console.log('Import successful:', response.data);
    return response.data;
  } catch (error) {
    console.error('Error importing file:', error);
    throw error;
  }
}