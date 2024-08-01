import { getToken, invalidToken, isTokenValid, refreshToken } from '@/application/session/token';
import { ClientAPI, WorkspaceFolder, DuplicatePublishViewPayload } from '@appflowyinc/client-api-wasm';
import { AFCloudConfig } from '@/application/services/services.type';
import { DatabaseId, PublishViewMetaData, RowId, ViewId, ViewLayout } from '@/application/collab.type';
import { FolderView } from '@/application/types';
import { GlobalComment, Reaction } from '@/application/comment.type';

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
      database_row_collabs: Record<RowId, number[]>;
      database_row_document_collabs: Record<string, number[]>;
      visible_database_view_ids: ViewId[];
      database_relations: Record<DatabaseId, ViewId>;
    };

    return {
      data: res.database_collab,
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

export async function getWorkspaces() {
  try {
    const { data } = await client.get_workspaces();

    return data.map((workspace) => ({
      id: workspace.workspace_id,
      name: workspace.workspace_name,
      icon: workspace.icon,
      memberCount: workspace.member_count || 0,
    }));
  } catch (e) {
    return Promise.reject(e);
  }
}

export async function getWorkspaceFolder(workspaceId: string): Promise<FolderView> {
  try {
    const data = await client.get_folder(workspaceId);

    // eslint-disable-next-line no-inner-declarations
    function iterateFolder(folder: WorkspaceFolder): FolderView {
      return {
        id: folder.view_id,
        name: folder.name,
        icon: folder.icon,
        isSpace: folder.is_space,
        extra: folder.extra,
        isPrivate: folder.is_private,
        children: folder.children.map((child: WorkspaceFolder) => {
          return iterateFolder(child);
        }),
      };
    }

    return iterateFolder(data);
  } catch (e) {
    return Promise.reject(e);
  }
}

export function getCurrentUser() {
  return client.get_user();
}

export function duplicatePublishView(payload: DuplicatePublishViewPayload) {
  return client.duplicate_publish_view(payload);
}

export async function getPublishViewComments(viewId: string): Promise<GlobalComment[]> {
  try {
    const { comments } = await client.get_publish_view_comments(viewId);

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
  } catch (e) {
    return Promise.reject(e);
  }
}

export async function createGlobalCommentOnPublishView(viewId: string, content: string, replyCommentId?: string) {
  return client.create_comment_on_publish_view(viewId, content, replyCommentId);
}

export async function deleteGlobalCommentOnPublishView(viewId: string, commentId: string) {
  return client.delete_comment_on_publish_view(viewId, commentId);
}

export async function getReactions(viewId: string, commentId?: string): Promise<Record<string, Reaction[]>> {
  try {
    const { reactions } = await client.get_reactions(viewId, commentId);

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
  } catch (e) {
    return Promise.reject(e);
  }
}

export async function addReaction(viewId: string, commentId: string, reactionType: string) {
  return client.create_reaction(viewId, commentId, reactionType);
}

export async function removeReaction(viewId: string, commentId: string, reactionType: string) {
  return client.delete_reaction(viewId, commentId, reactionType);
}
