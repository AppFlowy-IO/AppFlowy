import {
  Invitation,
  DuplicatePublishView,
  FolderView,
  User,
  UserWorkspaceInfo,
  View,
  Workspace,
  YDoc, DatabaseRelations, GetRequestAccessInfoResponse, Subscriptions, SubscriptionPlan, SubscriptionInterval, Types,
} from '@/application/types';
import { GlobalComment, Reaction } from '@/application/comment.type';
import { ViewMeta } from '@/application/db/tables/view_metas';
import {
  Template,
  TemplateCategory,
  TemplateCategoryFormValues,
  TemplateCreator, TemplateCreatorFormValues, TemplateSummary,
  UploadTemplatePayload,
} from '@/application/template.type';

export type AFService = PublishService & AppService & TemplateService & {
  getClientId: () => string;
};

export interface AFServiceConfig {
  cloudConfig: AFCloudConfig;
}

export interface AFCloudConfig {
  baseURL: string;
  gotrueURL: string;
  wsURL: string;
}

export interface AppService {
  openWorkspace: (workspaceId: string) => Promise<void>;
  getPageDoc: (workspaceId: string, viewId: string, errorCallback?: (error: {
    code: number;
  }) => void) => Promise<YDoc>;
  createRowDoc: (rowKey: string) => Promise<YDoc>;
  deleteRowDoc: (rowKey: string) => void;
  getAppDatabaseViewRelations: (workspaceId: string, databaseStorageId: string) => Promise<DatabaseRelations>;
  getAppOutline: (workspaceId: string) => Promise<View[]>;
  getAppView: (workspaceId: string, viewId: string) => Promise<View>;
  getAppFavorites: (workspaceId: string) => Promise<View[]>;
  getAppRecent: (workspaceId: string) => Promise<View[]>;
  getAppTrash: (workspaceId: string) => Promise<View[]>;
  loginAuth: (url: string) => Promise<void>;
  signInMagicLink: (params: { email: string; redirectTo: string }) => Promise<void>;
  signInGoogle: (params: { redirectTo: string }) => Promise<void>;
  signInGithub: (params: { redirectTo: string }) => Promise<void>;
  signInDiscord: (params: { redirectTo: string }) => Promise<void>;
  signInApple: (params: { redirectTo: string }) => Promise<void>;
  getWorkspaces: () => Promise<Workspace[]>;
  getWorkspaceFolder: (workspaceId: string) => Promise<FolderView>;
  getCurrentUser: () => Promise<User>;
  getUserWorkspaceInfo: () => Promise<UserWorkspaceInfo>;
  uploadFileToCDN: (file: File) => Promise<string>;
  getInvitation: (invitationId: string) => Promise<Invitation>;
  acceptInvitation: (invitationId: string) => Promise<void>;
  getRequestAccessInfo: (requestId: string) => Promise<GetRequestAccessInfoResponse>;
  approveRequestAccess: (requestId: string) => Promise<void>;
  sendRequestAccess: (workspaceId: string, viewId: string) => Promise<void>;
  getSubscriptionLink: (workspaceId: string, plan: SubscriptionPlan, interval: SubscriptionInterval) => Promise<string>;
  getSubscriptions: () => Promise<Subscriptions>;
  getActiveSubscription: (workspaceId: string) => Promise<SubscriptionPlan[]>;
  registerDocUpdate: (doc: YDoc, context: {
    workspaceId: string, objectId: string, collabType: Types
  }) => void;
  importFile: (file: File, onProgress: (progress: number) => void) => Promise<void>;
}

export interface TemplateService {
  getTemplateCategories: () => Promise<TemplateCategory[]>;
  addTemplateCategory: (category: TemplateCategoryFormValues) => Promise<void>;
  deleteTemplateCategory: (categoryId: string) => Promise<void>;
  getTemplateCreators: () => Promise<TemplateCreator[]>;
  createTemplateCreator: (creator: TemplateCreatorFormValues) => Promise<void>;
  deleteTemplateCreator: (creatorId: string) => Promise<void>;
  getTemplateById: (id: string) => Promise<Template>;
  getTemplates: (params: {
    categoryId?: string;
    nameContains?: string;
  }) => Promise<TemplateSummary[]>;
  deleteTemplate: (id: string) => Promise<void>;
  createTemplate: (template: UploadTemplatePayload) => Promise<void>;
  updateTemplate: (id: string, template: UploadTemplatePayload) => Promise<void>;
  updateTemplateCategory: (categoryId: string, category: TemplateCategoryFormValues) => Promise<void>;
  updateTemplateCreator: (creatorId: string, creator: TemplateCreatorFormValues) => Promise<void>;
}

export interface PublishService {

  getPublishViewMeta: (namespace: string, publishName: string) => Promise<ViewMeta>;
  getPublishView: (namespace: string, publishName: string) => Promise<YDoc>;
  getPublishRowDocument: (viewId: string) => Promise<YDoc>;
  getPublishInfo: (viewId: string) => Promise<{ namespace: string; publishName: string }>;

  getPublishOutline (namespace: string): Promise<View[]>;

  getPublishViewGlobalComments: (viewId: string) => Promise<GlobalComment[]>;
  createCommentOnPublishView: (viewId: string, content: string, replyCommentId?: string) => Promise<void>;
  deleteCommentOnPublishView: (viewId: string, commentId: string) => Promise<void>;
  getPublishViewReactions: (viewId: string, commentId?: string) => Promise<Record<string, Reaction[]>>;
  addPublishViewReaction: (viewId: string, commentId: string, reactionType: string) => Promise<void>;
  removePublishViewReaction: (viewId: string, commentId: string, reactionType: string) => Promise<void>;
  duplicatePublishView: (params: DuplicatePublishView) => Promise<void>;

}
