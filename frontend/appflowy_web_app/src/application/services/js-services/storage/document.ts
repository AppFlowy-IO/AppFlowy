import { YjsEditorKey } from '@/application/document.type';
import { openCollabDB } from '@/application/services/js-services/db';

export async function getDocumentStorage (docName: string) {
  const doc = await openCollabDB(
    docName,
  );
  const localExist = doc.share.has(YjsEditorKey.data_section);

  return {
    doc,
    localExist,
  };
}