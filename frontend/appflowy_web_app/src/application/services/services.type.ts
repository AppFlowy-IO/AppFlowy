import { YDoc } from '@/application/collab.type';
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
