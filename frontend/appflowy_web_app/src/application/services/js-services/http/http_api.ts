import { DatabaseId, RowId, ViewId, ViewLayout } from '@/application/collab.type';
import { GlobalComment, Reaction } from '@/application/comment.type';
import { initGrantService, refreshToken } from '@/application/services/js-services/http/gotrue';
import { blobToBytes } from '@/application/services/js-services/http/utils';
import { AFCloudConfig } from '@/application/services/services.type';
import { getTokenParsed, invalidToken } from '@/application/session/token';
import { FolderView, User, Workspace } from '@/application/types';
import axios, { AxiosInstance } from 'axios';
import dayjs from 'dayjs';

export * from './gotrue';

let axiosInstance: AxiosInstance | null = null;

export function initAPIService(config: AFCloudConfig) {
  if (axiosInstance) {
    return;
  }

  axiosInstance = axios.create({
    baseURL: config.baseURL,
  });

  initGrantService(config.gotrueURL);

  axiosInstance.interceptors.request.use(
    async (config) => {
      const token = getTokenParsed();

      Object.assign(config.headers, {
        'Content-Type': 'application/json',
      });

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
    }
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

export async function signInWithUrl(url: string) {
  const hash = new URL(url).hash;

  if (!hash) {
    return Promise.reject('No hash found');
  }

  const params = new URLSearchParams(hash.slice(1));
  const refresh_token = params.get('refresh_token');

  if (!refresh_token) {
    return Promise.reject('No access_token found');
  }

  await refreshToken(refresh_token);
}

export async function verifyToken(accessToken: string) {
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

export async function getCurrentUser(): Promise<User> {
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
    };
  }

  return Promise.reject(data);
}

export async function getPublishViewMeta(namespace: string, publishName: string) {
  const url = `/api/workspace/published/${namespace}/${publishName}`;
  const response = await axiosInstance?.get(url);

  return response?.data;
}

export async function getPublishViewBlob(namespace: string, publishName: string) {
  const url = `/api/workspace/published/${namespace}/${publishName}/blob`;
  const response = await axiosInstance?.get(url, {
    responseType: 'blob',
  });

  return blobToBytes(response?.data);
}

export async function getPublishView(publishNamespace: string, publishName: string) {
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
      meta,
    };
  } catch (e) {
    return Promise.reject(e);
  }
}

export async function getPublishInfoWithViewId(viewId: string) {
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

export async function getPublishViewComments(viewId: string): Promise<GlobalComment[]> {
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

export async function getReactions(viewId: string, commentId?: string): Promise<Record<string, Reaction[]>> {
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

export async function createGlobalCommentOnPublishView(viewId: string, content: string, replyCommentId?: string) {
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

export async function deleteGlobalCommentOnPublishView(viewId: string, commentId: string) {
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

export async function addReaction(viewId: string, commentId: string, reactionType: string) {
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

export async function removeReaction(viewId: string, commentId: string, reactionType: string) {
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

export async function getWorkspaces(): Promise<Workspace[]> {
  const query = new URLSearchParams({
    include_member_count: 'true',
  });

  const url = `/api/workspace?${query.toString()}`;
  const response = await axiosInstance?.get<{
    code: number;
    data?: {
      workspace_id: string;
      workspace_name: string;
      member_count: number;
      icon: string;
    }[];
    message: string;
  }>(url);

  const data = response?.data;

  if (data?.code === 0 && data.data) {
    return data.data.map((workspace) => {
      return {
        id: workspace.workspace_id,
        name: workspace.workspace_name,
        memberCount: workspace.member_count,
        icon: workspace.icon,
      };
    });
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

function iterateFolder(folder: WorkspaceFolder): FolderView {
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

export async function getWorkspaceFolder(workspaceId: string): Promise<FolderView> {
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

export async function duplicatePublishView(workspaceId: string, payload: DuplicatePublishViewPayload) {
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
