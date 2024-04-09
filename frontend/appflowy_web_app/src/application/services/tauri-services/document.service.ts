import { DocumentService } from '@/application/services/services.type';
import { OpenDocumentPayloadPB } from './backend';
import { DocumentEventOpenDocument } from './backend/events/flowy-document';

export class TauriDocumentService implements DocumentService {
  async openDocument(docId: string): Promise<void> {
    const payload = OpenDocumentPayloadPB.fromObject({
      document_id: docId,
    });

    const result = await DocumentEventOpenDocument(payload);

    if (!result.ok) {
      return Promise.reject(result.val);
    }

    return;

    // const documentDataPB = result.val;
    //
    // if (!documentDataPB) {
    //   return Promise.reject('documentDataPB is null');
    // }
    //
    // const data: {
    //   viewId: string;
    //   rootId: string;
    //   nodeMap: Record<string, any>;
    //   childrenMap: Record<string, string[]>;
    //   relativeMap: Record<string, string>;
    //   deltaMap: Record<string, Op[]>;
    //   externalIdMap: Record<string, string>;
    // } = {
    //   viewId: docId,
    //   rootId: documentDataPB.page_id,
    //   nodeMap: {},
    //   childrenMap: {},
    //   relativeMap: {},
    //   deltaMap: {},
    //   externalIdMap: {},
    // };
    //
    // get(documentDataPB, BLOCK_MAP_NAME).forEach((block) => {
    //   Object.assign(data.nodeMap, {
    //     [block.id]: blockPB2Node(block),
    //   });
    //   data.relativeMap[block.children_id] = block.id;
    //   if (block.external_id) {
    //     data.externalIdMap[block.external_id] = block.id;
    //   }
    // });
    //
    // get(documentDataPB, [META_NAME, CHILDREN_MAP_NAME]).forEach((child, key) => {
    //   const blockId = data.relativeMap[key];
    //
    //   data.childrenMap[blockId] = child.children;
    // });
    //
    // get(documentDataPB, [META_NAME, TEXT_MAP_NAME]).forEach((delta, key) => {
    //   const blockId = data.externalIdMap[key];
    //
    //   data.deltaMap[blockId] = delta ? JSON.parse(delta) : [];
    // });
    //
    // // return data;
    // return;
  }
}
