import { YDoc } from '@/application/collab.type';
import {
  deleteView,
  getBatchCollabs,
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
} from '@/application/services/js-services/wasm/client_api';
import { AFService, AFServiceConfig } from '@/application/services/services.type';
import { emit, EventType } from '@/application/session';
import { afterAuth, AUTH_CALLBACK_URL, withSignIn } from '@/application/session/sign_in';
import { nanoid } from 'nanoid';
import * as Y from 'yjs';

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
    const viewMeta = await getPublishViewMeta(
      () => {
        return fetchPublishViewMeta(namespace, publishName);
      },
      {
        namespace,
        publishName,
      },
      StrategyType.CACHE_AND_NETWORK
    );

    if (!viewMeta) {
      return Promise.reject(new Error('View has not been published yet'));
    }

    return viewMeta;
  }

  async getPublishView(namespace: string, publishName: string) {
    const name = `${namespace}_${publishName}`;

    const isLoaded = this.publishViewLoaded.has(name);

    const doc = await getPublishView(
      async () => {
        try {
          return await fetchPublishView(namespace, publishName);
        } catch (e) {
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

    return doc;
  }

  async getPublishDatabaseViewRows(namespace: string, publishName: string, rowIds: string[]) {
    const name = `${namespace}_${publishName}`;

    if (!this.publishViewLoaded.has(name)) {
      await this.getPublishView(namespace, publishName);
    }

    const rootRowsDoc =
      this.cacheDatabaseRowDocMap.get(name) ??
      new Y.Doc({
        guid: name,
      });

    if (!this.cacheDatabaseRowDocMap.has(name)) {
      this.cacheDatabaseRowDocMap.set(name, rootRowsDoc);
    }

    const rowsFolder: Y.Map<YDoc> = rootRowsDoc.getMap();
    const docs = await getBatchCollabs(rowIds.map((id) => `${name}_${id}`));

    docs.forEach((doc, index) => {
      rowsFolder.set(rowIds[index], doc);
    });

    console.log('getPublishDatabaseViewRows', docs);
    return {
      rows: rowsFolder,
      destroy: () => {
        this.cacheDatabaseRowDocMap.delete(name);
        rootRowsDoc.destroy();
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
}
