import { GlobalComment, Reaction } from '@/application/comment.type';
import { openCollabDB } from '@/application/db';
import {
  createRowDoc, deleteRowDoc,
  deleteView,
  getPageDoc,
  getPublishView,
  getPublishViewMeta,
  getUser, hasCollabCache,
  hasViewMetaCache,
} from '@/application/services/js-services/cache';
import { StrategyType } from '@/application/services/js-services/cache/types';
import {
  fetchPageCollab,
  fetchPublishView,
  fetchPublishViewMeta,
  fetchViewInfo,
} from '@/application/services/js-services/fetch';
import { APIService } from '@/application/services/js-services/http';
import { SyncManager } from '@/application/services/js-services/sync';

import { AFService, AFServiceConfig } from '@/application/services/services.type';
import { emit, EventType } from '@/application/session';
import { afterAuth, AUTH_CALLBACK_URL, withSignIn } from '@/application/session/sign_in';
import { getTokenParsed } from '@/application/session/token';
import {
  TemplateCategoryFormValues,
  TemplateCreatorFormValues,
  UploadTemplatePayload,
} from '@/application/template.type';
import {
  DatabaseRelations,
  DuplicatePublishView,
  SubscriptionInterval, SubscriptionPlan,
  Types,
  YjsEditorKey,
} from '@/application/types';
import { applyYDoc } from '@/application/ydoc/apply';
import { nanoid } from 'nanoid';
import * as Y from 'yjs';

export class AFClientService implements AFService {
  private deviceId: string = nanoid(8);

  private clientId: string = 'web';

  private viewLoaded: Set<string> = new Set();

  private publishViewLoaded: Set<string> = new Set();

  private publishViewInfo: Map<
    string,
    {
      namespace: string;
      publishName: string;
    }
  > = new Map();

  constructor (config: AFServiceConfig) {
    APIService.initAPIService(config.cloudConfig);
  }

  getClientId () {
    return this.clientId;
  }

  async getPublishViewMeta (namespace: string, publishName: string) {
    const name = `${namespace}_${publishName}`;

    const isLoaded = this.publishViewLoaded.has(name);
    const viewMeta = await getPublishViewMeta(
      () => {
        return fetchPublishViewMeta(namespace, publishName);
      },
      {
        namespace,
        publishName,
      },
      isLoaded ? StrategyType.CACHE_FIRST : StrategyType.CACHE_AND_NETWORK,
    );

    if (!viewMeta) {
      return Promise.reject(new Error('View has not been published yet'));
    }

    return viewMeta;
  }

  async getPublishView (namespace: string, publishName: string) {
    const name = `${namespace}_${publishName}`;

    const isLoaded = this.publishViewLoaded.has(name);

    const { doc } = await getPublishView(
      async () => {
        try {
          return await fetchPublishView(namespace, publishName);
        } catch (e) {
          console.error(e);
          void (async () => {
            if (await hasViewMetaCache(name)) {
              this.publishViewLoaded.delete(name);
              void deleteView(name);
            }
          })();

          return Promise.reject(e);
        }
      },
      {
        namespace,
        publishName,
      },
      isLoaded ? StrategyType.CACHE_FIRST : StrategyType.CACHE_AND_NETWORK,
    );

    if (!isLoaded) {
      this.publishViewLoaded.add(name);
    }

    return doc;
  }

  async getPublishRowDocument (viewId: string) {
    const doc = await openCollabDB(viewId);

    if (hasCollabCache(doc)) {
      return doc;
    }

    return Promise.reject(new Error('Document not found'));

  }

  async createRowDoc (rowKey: string) {
    return createRowDoc(rowKey);
  }

  deleteRowDoc (rowKey: string) {
    return deleteRowDoc(rowKey);
  }

  async getAppDatabaseViewRelations (workspaceId: string, databaseStorageId: string) {

    const res = await APIService.getCollab(workspaceId, databaseStorageId, Types.WorkspaceDatabase);
    const doc = new Y.Doc();

    applyYDoc(doc, res.data);

    const { databases } = doc.getMap(YjsEditorKey.data_section).toJSON();
    const result: DatabaseRelations = {};

    databases.forEach((database: {
      database_id: string;
      views: string[]
    }) => {
      result[database.database_id] = database.views[0];
    });
    return result;
  }

  async getPublishInfo (viewId: string) {
    if (this.publishViewInfo.has(viewId)) {
      return this.publishViewInfo.get(viewId) as {
        namespace: string;
        publishName: string;
      };
    }

    const info = await fetchViewInfo(viewId);

    const namespace = info.namespace;

    if (!namespace) {
      return Promise.reject(new Error('View not found'));
    }

    const data = {
      namespace,
      publishName: info.publish_name,
    };

    this.publishViewInfo.set(viewId, data);

    return data;
  }

  async getPublishOutline (namespace: string) {
    return APIService.getPublishOutline(namespace);
  }

  async getAppOutline (workspaceId: string) {
    return APIService.getAppOutline(workspaceId);
  }

  async getAppView (workspaceId: string, viewId: string) {
    return APIService.getView(workspaceId, viewId);
  }

  async getAppFavorites (workspaceId: string) {
    return APIService.getAppFavorites(workspaceId);
  }

  async getAppRecent (workspaceId: string) {
    return APIService.getAppRecent(workspaceId);
  }

  async getAppTrash (workspaceId: string) {
    return APIService.getAppTrash(workspaceId);
  }

  async loginAuth (url: string) {
    try {
      await APIService.signInWithUrl(url);
      emit(EventType.SESSION_VALID);
      afterAuth();
      return;
    } catch (e) {
      emit(EventType.SESSION_INVALID);
      return Promise.reject(e);
    }
  }

  @withSignIn()
  async signInMagicLink ({ email }: { email: string; redirectTo: string }) {
    return await APIService.signInWithMagicLink(email, AUTH_CALLBACK_URL);
  }

  @withSignIn()
  async signInGoogle (_: { redirectTo: string }) {
    return APIService.signInGoogle(AUTH_CALLBACK_URL);
  }

  @withSignIn()
  async signInApple (_: { redirectTo: string }) {
    return APIService.signInApple(AUTH_CALLBACK_URL);
  }

  @withSignIn()
  async signInGithub (_: { redirectTo: string }) {
    return APIService.signInGithub(AUTH_CALLBACK_URL);
  }

  @withSignIn()
  async signInDiscord (_: { redirectTo: string }) {
    return APIService.signInDiscord(AUTH_CALLBACK_URL);
  }

  async getWorkspaces () {
    const data = APIService.getWorkspaces();

    return data;
  }

  async getWorkspaceFolder (workspaceId: string) {
    const data = await APIService.getWorkspaceFolder(workspaceId);

    return data;
  }

  async getCurrentUser () {
    const token = getTokenParsed();
    const userId = token?.user?.id;

    const user = await getUser(
      () => APIService.getCurrentUser(),
      userId,
      StrategyType.CACHE_AND_NETWORK,
    );

    if (!user) {
      return Promise.reject(new Error('User not found'));
    }

    return user;
  }

  async openWorkspace (workspaceId: string) {
    return APIService.openWorkspace(workspaceId);
  }

  async getUserWorkspaceInfo () {
    const workspaceInfo = await APIService.getUserWorkspaceInfo();

    if (!workspaceInfo) {
      return Promise.reject(new Error('Workspace info not found'));
    }

    return {
      userId: workspaceInfo.user_id,
      selectedWorkspace: workspaceInfo.selected_workspace,
      workspaces: workspaceInfo.workspaces,
    };
  }

  async duplicatePublishView (params: DuplicatePublishView) {
    return APIService.duplicatePublishView(params.workspaceId, {
      dest_view_id: params.spaceViewId,
      published_view_id: params.viewId,
      published_collab_type: params.collabType,
    });
  }

  createCommentOnPublishView (viewId: string, content: string, replyCommentId: string | undefined): Promise<void> {
    return APIService.createGlobalCommentOnPublishView(viewId, content, replyCommentId);
  }

  deleteCommentOnPublishView (viewId: string, commentId: string): Promise<void> {
    return APIService.deleteGlobalCommentOnPublishView(viewId, commentId);
  }

  getPublishViewGlobalComments (viewId: string): Promise<GlobalComment[]> {
    return APIService.getPublishViewComments(viewId);
  }

  getPublishViewReactions (viewId: string, commentId?: string): Promise<Record<string, Reaction[]>> {
    return APIService.getReactions(viewId, commentId);
  }

  addPublishViewReaction (viewId: string, commentId: string, reactionType: string): Promise<void> {
    return APIService.addReaction(viewId, commentId, reactionType);
  }

  removePublishViewReaction (viewId: string, commentId: string, reactionType: string): Promise<void> {
    return APIService.removeReaction(viewId, commentId, reactionType);
  }

  async getTemplateCategories () {
    return APIService.getTemplateCategories();
  }

  async getTemplateCreators () {
    return APIService.getTemplateCreators();
  }

  async createTemplate (template: UploadTemplatePayload) {
    return APIService.createTemplate(template);
  }

  async updateTemplate (id: string, template: UploadTemplatePayload) {
    return APIService.updateTemplate(id, template);
  }

  async getTemplateById (id: string) {
    return APIService.getTemplateById(id);
  }

  async getTemplates (params: {
    categoryId?: string;
    nameContains?: string;
  }) {
    return APIService.getTemplates(params);
  }

  async deleteTemplate (id: string) {
    return APIService.deleteTemplate(id);
  }

  async addTemplateCategory (category: TemplateCategoryFormValues) {
    return APIService.addTemplateCategory(category);
  }

  async updateTemplateCategory (categoryId: string, category: TemplateCategoryFormValues) {
    return APIService.updateTemplateCategory(categoryId, category);
  }

  async deleteTemplateCategory (categoryId: string) {
    return APIService.deleteTemplateCategory(categoryId);
  }

  async updateTemplateCreator (creatorId: string, creator: TemplateCreatorFormValues) {
    return APIService.updateTemplateCreator(creatorId, creator);
  }

  async createTemplateCreator (creator: TemplateCreatorFormValues) {
    return APIService.createTemplateCreator(creator);
  }

  async deleteTemplateCreator (creatorId: string) {
    return APIService.deleteTemplateCreator(creatorId);
  }

  async uploadFileToCDN (file: File) {
    return APIService.uploadFileToCDN(file);
  }

  async getPageDoc (workspaceId: string, viewId: string, errorCallback?: (error: {
    code: number;
  }) => void) {

    const token = getTokenParsed();
    const userId = token?.user.id;

    if (!userId) {
      throw new Error('User not found');
    }

    const name = `${userId}_${workspaceId}_${viewId}`;

    const isLoaded = this.viewLoaded.has(name);

    const { doc } = await getPageDoc(
      async () => {
        try {
          return await fetchPageCollab(workspaceId, viewId);
          // eslint-disable-next-line
        } catch (e: any) {
          console.error(e);

          errorCallback?.(e);
          void (async () => {
            this.viewLoaded.delete(name);
            void deleteView(name);
          })();

          return Promise.reject(e);
        }
      },
      name,
      isLoaded ? StrategyType.CACHE_FIRST : StrategyType.CACHE_AND_NETWORK,
    );

    if (!isLoaded) {
      this.viewLoaded.add(name);
    }

    return doc;
  }

  async getInvitation (invitationId: string) {
    return APIService.getInvitation(invitationId);
  }

  async acceptInvitation (invitationId: string) {
    return APIService.acceptInvitation(invitationId);
  }

  approveRequestAccess (requestId: string): Promise<void> {
    return APIService.approveRequestAccess(requestId);
  }

  getRequestAccessInfo (requestId: string) {
    return APIService.getRequestAccessInfo(requestId);
  }

  sendRequestAccess (workspaceId: string, viewId: string): Promise<void> {
    return APIService.sendRequestAccess(workspaceId, viewId);
  }

  getSubscriptionLink (workspaceId: string, plan: SubscriptionPlan, interval: SubscriptionInterval) {
    return APIService.getSubscriptionLink(workspaceId, plan, interval);
  }

  getSubscriptions () {
    return APIService.getSubscriptions();
  }

  getActiveSubscription (workspaceId: string) {
    return APIService.getActiveSubscription(workspaceId);
  }

  registerDocUpdate (doc: Y.Doc, workspaceId: string, objectId: string) {
    const token = getTokenParsed();
    const userId = token?.user.id;

    if (!userId) {
      throw new Error('User not found');
    }

    const sync = new SyncManager(doc, userId, workspaceId, objectId);

    sync.initialize();
  }

  uploadFile (file: File, onProgress: (progress: number) => void) {
    return APIService.uploadFile(file, onProgress);
  }

  async importFile (file: File, onProgress: (progress: number) => void) {
    const task = await APIService.createImportTask(file);

    await APIService.uploadImportFile(task.presignedUrl, file, onProgress);
  }
}
