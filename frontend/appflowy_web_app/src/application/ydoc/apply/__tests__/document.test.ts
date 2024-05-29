import { YjsEditorKey } from '@/application/collab.type';
import { applyYDoc } from '@/application/ydoc/apply';
import * as Y from 'yjs';
import * as docJson from '../../../../../cypress/fixtures/simple_doc.json';

describe('apply document', () => {
  it('should apply document', () => {
    const collab = new Y.Doc();
    const data = collab.getMap(YjsEditorKey.data_section);
    const document = new Y.Map();
    data.set(YjsEditorKey.document, document);

    const state = new Uint8Array(docJson.data.doc_state);
    applyYDoc(collab, state);
  });
});

export {};
