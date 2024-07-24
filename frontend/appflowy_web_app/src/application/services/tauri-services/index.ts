import { YDoc } from '@/application/collab.type';
import { AFService } from '@/application/services/services.type';
import { nanoid } from 'nanoid';
import { YMap } from 'yjs/dist/src/types/YMap';

export class AFClientService implements AFService {
  private deviceId: string = nanoid(8);

  private clientId: string = 'tauri';

  async getPublishView(_namespace: string, _publishName: string) {
    return Promise.reject('Method not implemented');
  }

  async getPublishInfo(_viewId: string) {
    return Promise.reject('Method not implemented');
  }

  async getPublishViewMeta(_namespace: string, _publishName: string) {
    return Promise.reject('Method not implemented');
  }

  getClientId(): string {
    return '';
  }

  loginAuth(_: string): Promise<void> {
    return Promise.resolve(undefined);
  }

  signInDiscord(_params: { redirectTo: string }): Promise<void> {
    return Promise.resolve(undefined);
  }

  signInGithub(_params: { redirectTo: string }): Promise<void> {
    return Promise.resolve(undefined);
  }

  signInGoogle(_params: { redirectTo: string }): Promise<void> {
    return Promise.resolve(undefined);
  }

  signInMagicLink(_params: { email: string; redirectTo: string }): Promise<void> {
    return Promise.resolve(undefined);
  }

  getPublishDatabaseViewRows(
    _namespace: string,
    _publishName: string
  ): Promise<{
    rows: YMap<YDoc>;
    destroy: () => void;
  }> {
    return Promise.reject('Method not implemented');
  }
}
