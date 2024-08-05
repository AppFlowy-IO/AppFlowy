import { YDoc } from '@/application/collab.type';
import { GlobalComment, Reaction } from '@/application/comment.type';
import { ViewMeta } from '@/application/db/tables/view_metas';
import * as Y from 'yjs';
import { DuplicatePublishView, FolderView, User, Workspace } from '@/application/types';

export type AFService = PublishService;

export interface AFServiceConfig {
  cloudConfig: AFCloudConfig;
}

export interface AFCloudConfig {
  baseURL: string;
  gotrueURL: string;
  wsURL: string;
}

export interface PublishService {
  getClientId: () => string;
  getPublishViewMeta: (namespace: string, publishName: string) => Promise<ViewMeta>;
  getPublishView: (namespace: string, publishName: string) => Promise<YDoc>;
  getPublishInfo: (viewId: string) => Promise<{ namespace: string; publishName: string }>;
  getPublishDatabaseViewRows: (
    namespace: string,
    publishName: string,
    rowIds?: string[]
  ) => Promise<{
    rows: Y.Map<YDoc>;
    destroy: () => void;
  }>;
  getPublishViewGlobalComments: (viewId: string) => Promise<GlobalComment[]>;
  createCommentOnPublishView: (viewId: string, content: string, replyCommentId?: string) => Promise<void>;
  deleteCommentOnPublishView: (viewId: string, commentId: string) => Promise<void>;
  getPublishViewReactions: (viewId: string, commentId?: string) => Promise<Record<string, Reaction[]>>;
  addPublishViewReaction: (viewId: string, commentId: string, reactionType: string) => Promise<void>;
  removePublishViewReaction: (viewId: string, commentId: string, reactionType: string) => Promise<void>;

  loginAuth: (url: string) => Promise<void>;
  signInMagicLink: (params: { email: string; redirectTo: string }) => Promise<void>;
  signInGoogle: (params: { redirectTo: string }) => Promise<void>;
  signInGithub: (params: { redirectTo: string }) => Promise<void>;
  signInDiscord: (params: { redirectTo: string }) => Promise<void>;

  getWorkspaces: () => Promise<Workspace[]>;
  getWorkspaceFolder: (workspaceId: string) => Promise<FolderView>;
  getCurrentUser: () => Promise<User>;
  duplicatePublishView: (params: DuplicatePublishView) => Promise<void>;
}
