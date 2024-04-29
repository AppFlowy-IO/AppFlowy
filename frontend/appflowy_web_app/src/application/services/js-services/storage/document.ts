import { YjsEditorKey } from '@/application/document.type';
import { openCollabDB } from '@/application/services/js-services/db';
import { getAuthInfo } from '@/application/services/js-services/storage/token';

export async function getDocumentStorage(docId: string) {
  const docName = getDocName(docId);
  const doc = await openCollabDB(docName);
  const localExist = doc.share.has(YjsEditorKey.data_section);

  return {
    doc,
    localExist,
  };
}

export function getDocName(docId: string) {
  const { uuid } = getAuthInfo() || {};

  if (!uuid) throw new Error('No user found');
  return `${uuid}_document_${docId}`;
}
