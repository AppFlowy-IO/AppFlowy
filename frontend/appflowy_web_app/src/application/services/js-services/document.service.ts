import { DocumentService } from '@/application/services/services.type';
import { HttpClient } from '@/application/services/js-services/http/client';
import { CollabType } from '@/application/services/js-services/http/http.type';

export class JSDocumentService implements DocumentService {
  constructor(private httpClient: HttpClient) {}

  async openDocument(docID: string): Promise<void> {
    const workspaceId = '9eebea03-3ed5-4298-86b2-a7f77856d48b';
    const docId = '26d5c8c1-1c66-459c-bc6c-f4da1a663348';
    const data = await this.httpClient.getObject(workspaceId, docId, CollabType.Document);

    console.log(docID, data);

    return;
  }
}
