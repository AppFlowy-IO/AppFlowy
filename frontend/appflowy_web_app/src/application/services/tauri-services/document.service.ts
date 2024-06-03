import { DocumentService } from '@/application/services/services.type';
import * as Y from 'yjs';

export class TauriDocumentService implements DocumentService {
  async openDocument(_id: string): Promise<Y.Doc> {
    return Promise.reject('Not implemented');
  }
}
