import { AFService } from '@/application/services/services.type';
import { nanoid } from 'nanoid';

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

  async getPublishDatabaseViewRows(_namespace: string, _publishName: string, _rowIds: string[]) {
    return Promise.reject('Method not implemented');
  }
}
