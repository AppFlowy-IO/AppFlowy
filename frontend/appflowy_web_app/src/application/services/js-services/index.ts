import { YDoc } from '@/application/collab.type';
import { GlobalComment, Reaction } from '@/application/comment.type';
import {
  deleteView,
  getPublishView,
  getPublishViewMeta,
  hasViewMetaCache,
} from '@/application/services/js-services/cache';
import { StrategyType } from '@/application/services/js-services/cache/types';
import { fetchPublishView, fetchPublishViewMeta, fetchViewInfo } from '@/application/services/js-services/fetch';
import {
  initAPIService,
  signInGoogle,
  signInWithMagicLink,
  signInGithub,
  signInDiscord,
  signInWithUrl,
  createGlobalCommentOnPublishView,
  deleteGlobalCommentOnPublishView,
  getPublishViewComments,
  getWorkspaces,
  getWorkspaceFolder,
  getCurrentUser,
  duplicatePublishView,
  getReactions,
  addReaction,
  removeReaction,
} from '@/application/services/js-services/wasm/client_api';
import { AFService, AFServiceConfig } from '@/application/services/services.type';
import { emit, EventType } from '@/application/session';
import { afterAuth, AUTH_CALLBACK_URL, withSignIn } from '@/application/session/sign_in';
import { nanoid } from 'nanoid';
import * as Y from 'yjs';
import { DuplicatePublishView } from '@/application/types';

export class AFClientService implements AFService {
  private deviceId: string = nanoid(8);

  private clientId: string = 'web';

  private publishViewLoaded: Set<string> = new Set();

  private publishViewInfo: Map<
    string,
    {
      namespace: string;
      publishName: string;
    }
  > = new Map();

  private cacheDatabaseRowDocMap: Map<string, Y.Doc> = new Map();

  private cacheDatabaseRowFolder: Map<string, Y.Map<YDoc>> = new Map();

  constructor(config: AFServiceConfig) {
    initAPIService({
      ...config.cloudConfig,
      deviceId: this.deviceId,
      clientId: this.clientId,
    });
  }

  getClientId() {
    return this.clientId;
  }

  async getPublishViewMeta(namespace: string, publishName: string) {
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
      isLoaded ? StrategyType.CACHE_FIRST : StrategyType.CACHE_AND_NETWORK
    );

    if (!viewMeta) {
      return Promise.reject(new Error('View has not been published yet'));
    }

    return viewMeta;
  }

  async getPublishView(namespace: string, publishName: string) {
    const name = `${namespace}_${publishName}`;

    const isLoaded = this.publishViewLoaded.has(name);

    const { doc, rowMapDoc } = await getPublishView(
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
      isLoaded ? StrategyType.CACHE_FIRST : StrategyType.CACHE_AND_NETWORK
    );

    if (!isLoaded) {
      this.publishViewLoaded.add(name);
    }

    this.cacheDatabaseRowDocMap.set(name, rowMapDoc);

    return doc;
  }

  async getPublishDatabaseViewRows(namespace: string, publishName: string) {
    const name = `${namespace}_${publishName}`;

    if (!this.publishViewLoaded.has(name) || !this.cacheDatabaseRowDocMap.has(name)) {
      await this.getPublishView(namespace, publishName);
    }

    const rootRowsDoc = this.cacheDatabaseRowDocMap.get(name);

    if (!rootRowsDoc) {
      return Promise.reject(new Error('Root rows doc not found'));
    }

    if (!this.cacheDatabaseRowFolder.has(name)) {
      const rowsFolder: Y.Map<YDoc> = rootRowsDoc.getMap();

      this.cacheDatabaseRowFolder.set(name, rowsFolder);
    }

    const rowsFolder = this.cacheDatabaseRowFolder.get(name)!;

    return {
      rows: rowsFolder,
      destroy: () => {
        this.cacheDatabaseRowFolder.delete(name);
        this.cacheDatabaseRowDocMap.delete(name);
      },
    };
  }

  async getPublishInfo(viewId: string) {
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

  async loginAuth(url: string) {
    try {
      console.log('loginAuth', url);
      await signInWithUrl(url);
      emit(EventType.SESSION_VALID);
      afterAuth();
      return;
    } catch (e) {
      emit(EventType.SESSION_INVALID);
      return Promise.reject(e);
    }
  }

  @withSignIn()
  async signInMagicLink({ email }: { email: string; redirectTo: string }) {
    return await signInWithMagicLink(email, AUTH_CALLBACK_URL);
  }

  @withSignIn()
  async signInGoogle(_: { redirectTo: string }) {
    return await signInGoogle(AUTH_CALLBACK_URL);
  }

  @withSignIn()
  async signInGithub(_: { redirectTo: string }) {
    return await signInGithub(AUTH_CALLBACK_URL);
  }

  @withSignIn()
  async signInDiscord(_: { redirectTo: string }) {
    return await signInDiscord(AUTH_CALLBACK_URL);
  }

  async getWorkspaces() {
    const data = getWorkspaces();

    return data;
  }

  async getWorkspaceFolder(workspaceId: string) {
    const data = await getWorkspaceFolder(workspaceId);

    return data;
  }

  async getCurrentUser() {
    const data = await getCurrentUser();

    return {
      uid: data.uid,
      email: data.email,
      name: data.name,
      avatar: data.icon_url,
      uuid: data.uuid,
    };
  }

  async duplicatePublishView(params: DuplicatePublishView) {
    return duplicatePublishView({
      workspace_id: params.workspaceId,
      dest_view_id: params.spaceViewId,
      published_view_id: params.viewId,
      published_collab_type: params.collabType,
    });
  }

  createCommentOnPublishView(viewId: string, content: string, replyCommentId: string | undefined): Promise<void> {
    return createGlobalCommentOnPublishView(viewId, content, replyCommentId);
  }

  deleteCommentOnPublishView(viewId: string, commentId: string): Promise<void> {
    return deleteGlobalCommentOnPublishView(viewId, commentId);
  }

  getPublishViewGlobalComments(viewId: string): Promise<GlobalComment[]> {
    return getPublishViewComments(viewId);
  }

  getPublishViewReactions(viewId: string, commentId?: string): Promise<Record<string, Reaction[]>> {
    return getReactions(viewId, commentId);
  }

  addPublishViewReaction(viewId: string, commentId: string, reactionType: string): Promise<void> {
    return addReaction(viewId, commentId, reactionType);
  }

  removePublishViewReaction(viewId: string, commentId: string, reactionType: string): Promise<void> {
    return removeReaction(viewId, commentId, reactionType);
  }
}
